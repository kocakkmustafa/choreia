#!/usr/bin/env python3
"""Diz-sürücülü pencere probe'u — çapa-uyumsuzluğu mu, taban-yakını hareket mi?

Neden bu araç var
-----------------
`hh_bounce`'ın üç take'i de `prepare_take`'ten geçti ama seçilen pencerelerde diz
aralığı 10,9-29,5°'ydi (çalışan Running Man referansında 84,8°/41,2°) ve
`AyzYABnWDEM`'in sağ diz std'si 1,7° — hattın 6,0° gürültü tabanının ALTINDA.
Üç take'in üçünde de çapa `ankle-x` seçildi.

Aile ilkesi (M-F-195): **segment bulucu, adımın KENDİ faz-sürücüsünü kullanır.**
Bounce'ın faz tanımı diz-sürücülü, bulucusu ayak-çapalı — tutarsızlık burada.

Bu probe iki açıklamayı AYIRT eder, yeni hasat yapmadan, aynı take'ler üzerinde:

  (a) ÇAPA UYUMSUZLUĞU — diz-sürücülü pencereleme güçlü sinyal buluyorsa,
      ayak-çapası yanlış pencereyi seçmiş demektir. İlke config'e iner.
  (b) TABAN-YAKINI HAREKET — diz pencereleri de zayıfsa, `hh_bounce`'ın
      `measurability.tier: A` beyanı YANLIŞ ve adım demo-only yoluna girer.

**İki son da dürüsttür.** Bu araç hangisinin doğru olduğunu söylemez, ÖLÇER.

Ölçünün adımın KENDİ diliyle olması
-----------------------------------
Karar, uydurduğum bir eşikle değil, adım config'inin kendi faz tanımıyla verilir
(`top` girişi ve `drop` hız eşiği oradan OKUNUR). Kendi eşiğimi uydursaydım
cevabı da uydurmuş olurdum.

Açı hesabı `prepare_take`'ten İÇE AKTARILIR, yeniden yazılmaz: iki yerde tutulan
açı tanımı ayrışır (M-F-03).

PENCERE TARAMASI AYRIŞTIRMADI — ve bu kayıtlı bir sonuçtur
-----------------------------------------------------------
İlk tasarım "en güçlü diz penceresini bul" idi. İki kez imkânsız sayı üretti
(genlik 173°, düşüş 3031°/s: bir diz ayakta 6°'ye bükülmez). Sebep yapısal:
tek bir istatistikle "en iyi pencere" aramak, izleme dropout'u olan videoda
hareketi değil EN KÖTÜ İZLENEN yeri bulur — `max-min` en aykırı-duyarlı
istatistiktir. p5-p95'e ve medyan filtresine geçmek de yetmedi, çünkü bozuk
kareler global olarak binde-iki ama SEÇİLEN pencerede yoğunlaşıyor.

Ders (bu deponun kendi dersinin tekrarı, `build_reference`: "derece cinsinden
tek bir maks yanlış istatistiktir"): **arama kendi hedefini bozabilir.** Pencere
taraması aşağıda kayıtlı ama HÜKME ESAS DEĞİL.

Ayrıştıran ölçü, pencere SEÇMEYEN ölçüdür
------------------------------------------
Tüm video üzerinden diz açısı dağılımı, hattın KABUL ETTİĞİ take'lerle
karşılaştırılır. Pencere seçimi tartışmalı değişkendi; bu ölçü ona hiç
dokunmuyor. Karşılaştırma tabanı uydurma değil: Running Man referansının
gerçekten kullanılan kaynakları.

RAPOR-ONLY — hiçbir artefakt yazmaz, hiçbir config değiştirmez.

  python3 tools/probe_knee_windows.py --step hh_bounce ID [ID ...]
"""
from __future__ import annotations

import argparse
import json
import statistics as st
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from prepare_take import (  # noqa: E402
    aspect_of,
    joint_series,
    load_take,
    to_isotropic,
)

ROOT = Path(__file__).resolve().parents[1]

# Pencere uzunluğu: adımın çevriminden birkaç tekrar sığacak kadar. Sabit değil
# çünkü periyot bilinmiyor — birkaç uzunluk denenir ve en iyisi raporlanır.
WINDOW_SECONDS = (3.0, 5.0, 8.0)
STRIDE_SECONDS = 0.5


def step_config(step: str) -> dict:
    for p in ROOT.glob(f"content/styles/*/steps/{step}.json"):
        return json.loads(p.read_text(encoding="utf-8"))
    raise SystemExit(f"{step}: adım config'i bulunamadı")


def phase_thresholds(cfg: dict) -> tuple[float | None, float | None]:
    """(top giriş açısı, drop hız eşiği °/s) — adımın KENDİ tanımından."""
    top = drop = None
    for ph in cfg.get("phases") or []:
        enter = ph.get("enter") or {}
        if ph.get("id") == "top" and enter.get("op") == ">":
            top = float(enter["valueDeg"])
        if ph.get("id") == "drop" and enter.get("minRateDegPerSec") is not None:
            drop = float(enter["minRateDegPerSec"])
    return top, drop


def knee_mean_series(video_id: str) -> tuple[list[float], float]:
    """Ortalama diz açısı serisi (°) + fps. NaN'ler taşınır, doldurulmaz."""
    _doc, lm, _world, _keep, fps = load_take(video_id)
    iso = to_isotropic(lm, aspect_of(video_id))
    j = joint_series(iso)
    left, right = j.get("left_knee") or [], j.get("right_knee") or []
    out: list[float] = []
    for i in range(min(len(left), len(right))):
        a, b = left[i], right[i]
        # Tek diz görünmüyorsa ORTALAMA alınmaz: yarım kanıttan tam sayı
        # üretmek, görünürlük kapısının engellemek için var olduğu şey.
        if a != a or b != b:
            out.append(float("nan"))
        else:
            out.append((a + b) / 2.0)
    return out, fps


def _median3(xs: list[float]) -> list[float]:
    """3-noktalı medyan filtresi: tek-kare sıçramalarını siler, kenarı korur."""
    out = list(xs)
    for i in range(1, len(xs) - 1):
        w = [v for v in (xs[i - 1], xs[i], xs[i + 1]) if v == v]
        if w:
            out[i] = sorted(w)[len(w) // 2]
    return out


def pct(sorted_vals: list[float], p: float) -> float:
    return sorted_vals[int(p * (len(sorted_vals) - 1))]


def robust_drop_rate(win: list[float], fps: float) -> float:
    """En hızlı DÜŞÜŞ (°/s), medyan-filtreli seriden ve p95 olarak.

    Ham `max` burada kullanılamaz: ilk sürüm 3031°/s bildirdi — tek bir bozuk
    karenin ürünü, fizyolojik olarak imkânsız. Bu deponun kendi dersi
    (`build_reference`: "derece cinsinden tek bir maks yanlış istatistiktir")
    burada yeniden öğrenildi.
    """
    sm = _median3(win)
    rates = []
    for i in range(1, len(sm)):
        a, b = sm[i - 1], sm[i]
        if a != a or b != b:
            continue
        rates.append((a - b) * fps)     # pozitif = açı azalıyor
    if not rates:
        return 0.0
    return max(0.0, pct(sorted(rates), 0.99))


def scan(series: list[float], fps: float, top_deg: float | None,
         drop_rate: float | None) -> list[dict]:
    """Her pencere uzunluğu için en iyi pencereyi bul (genliğe göre)."""
    results = []
    stride = max(1, int(STRIDE_SECONDS * fps))
    for wsec in WINDOW_SECONDS:
        w = int(wsec * fps)
        if w >= len(series):
            continue
        best = None
        for i in range(0, len(series) - w, stride):
            win = series[i:i + w]
            vals = [v for v in win if v == v]
            # Yarıdan fazlası görünmeyen pencere ölçülmez; "veri yok" ile
            # "hareket yok" karıştırılamaz.
            if len(vals) < 0.5 * w:
                continue
            sv = sorted(vals)
            # SAĞLAM genlik: p5-p95. max-min, izleme dropout'u olan veride
            # hareketi değil EN KÖTÜ GLITCH'i ölçer (ilk sürümün hatası).
            amp = pct(sv, 0.95) - pct(sv, 0.05)
            cand = {
                "windowSeconds": wsec,
                "startSeconds": round(i / fps, 2),
                "amplitudeDeg": round(amp, 1),
                "rawAmplitudeDeg": round(max(vals) - min(vals), 1),
                "maxAngleDeg": round(pct(sv, 0.95), 1),
                "minAngleDeg": round(pct(sv, 0.05), 1),
                "stdDeg": round(st.pstdev(vals), 1),
                "maxDropRateDegPerSec": round(robust_drop_rate(win, fps), 1),
                "coverage": round(len(vals) / w, 2),
            }
            if best is None or cand["amplitudeDeg"] > best["amplitudeDeg"]:
                best = cand
        if best is None:
            continue
        # Adımın KENDİ eşikleri. Eşik yoksa hüküm de yok — uydurulmaz.
        best["meetsTop"] = (None if top_deg is None
                            else best["maxAngleDeg"] >= top_deg)
        best["meetsDrop"] = (None if drop_rate is None
                             else best["maxDropRateDegPerSec"] >= drop_rate)
        results.append(best)
    return results


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--step", required=True)
    ap.add_argument("videos", nargs="+")
    ap.add_argument("--baseline", nargs="*", default=[],
                    help="hattın KABUL ETTİĞİ take'ler — karşılaştırma tabanı")
    args = ap.parse_args()

    cfg = step_config(args.step)
    top_deg, drop_rate = phase_thresholds(cfg)
    print(f"adım: {args.step}  —  KENDİ faz eşikleri: "
          f"top ≥ {top_deg}°  ·  drop ≥ {drop_rate}°/s")
    print("genlik SAĞLAM (p5-p95); 'ham' sütunu max-min — aradaki uçurum "
          "izleme glitch'idir")
    print(f"gürültü tabanı karşılaştırması: MIN_TOLERANCE_DEG = 6.0°\n")

    verdicts = {}
    for vid in args.videos:
        print(f"── {vid} ──")
        try:
            series, fps = knee_mean_series(vid)
        except SystemExit as e:
            print(f"   atlandı: {e}\n")
            continue
        rows = scan(series, fps, top_deg, drop_rate)
        if not rows:
            print("   ölçülebilir pencere yok\n")
            continue
        print(f"   {'pencere':>8}{'başlangıç':>11}{'genlik°':>9}{'maks°':>8}"
              f"{'std°':>7}{'ham°':>7}{'düşüş°/s':>10}{'top':>6}{'drop':>6}")
        for r in rows:
            mt = "—" if r["meetsTop"] is None else ("✓" if r["meetsTop"] else "✗")
            md = "—" if r["meetsDrop"] is None else ("✓" if r["meetsDrop"] else "✗")
            print(f"   {r['windowSeconds']:>7}s{r['startSeconds']:>10}s"
                  f"{r['amplitudeDeg']:>9}{r['maxAngleDeg']:>8}{r['stdDeg']:>7}"
                  f"{r['rawAmplitudeDeg']:>7}"
                  f"{r['maxDropRateDegPerSec']:>10}{mt:>6}{md:>6}")
        best = max(rows, key=lambda r: r["amplitudeDeg"])
        verdicts[vid] = best
        print()

    if not verdicts:
        return 1

    print("═══ PENCERE TARAMASI — HÜKME ESAS DEĞİL ═══")
    print("(tek-istatistik arama izleme hatalarına kilitleniyor; 'ham' sütunu")
    print(" ile genlik arasındaki uçurum bunun ölçüsü)")
    print()
    print("═══ AYRIŞTIRAN ÖLÇÜ: dağılım karşılaştırması (pencere seçmez) ═══")
    print(f"  {'take':<16}{'p5°':>7}{'medyan°':>9}{'iniş°':>8}   rol")
    print("  " + "-"*52)
    rows = []
    for vid in list(args.baseline) + list(args.videos):
        try:
            series, _ = knee_mean_series(vid)
        except SystemExit:
            continue
        v = sorted(x for x in series if x == x)
        if not v:
            continue
        p5, med = pct(v, 0.05), pct(v, 0.5)
        rol = "TABAN (kabul edilmiş)" if vid in args.baseline else "aday"
        rows.append((vid, p5, med, med - p5, rol))
        print(f"  {vid:<16}{p5:>7.1f}{med:>9.1f}{med - p5:>8.1f}   {rol}")

    base = [r for r in rows if r[4].startswith("TABAN")]
    cand = [r for r in rows if r[4] == "aday"]
    if base and cand:
        bmed = st.median([r[3] for r in base])
        cmed = st.median([r[3] for r in cand])
        print()
        print(f"  kabul edilmiş take'lerin ortanca inişi : {bmed:.1f}°")
        print(f"  aday take'lerin ortanca inişi          : {cmed:.1f}°")
        print(f"  oran                                   : {bmed / cmed:.1f}×")
        print(f"  gürültü tabanı (MIN_TOLERANCE_DEG)     : 6.0°")
        print()
        if cmed < 6.0:
            print("  → ADAY SİNYALİ GÜRÜLTÜ TABANININ ALTINDA: (b) — hareket")
            print("    tek-kamerada ölçülemez, tier-A beyanı yanlış.")
        else:
            print("  → ADAY SİNYALİ TABANIN ÜSTÜNDE ama tabandan belirgin küçük.")
            print("    Bu, (a)/(b) ikilisinin İKİSİNİ DE tam karşılamıyor:")
            print("    hareket ölçülebilir, ama karşılaştırma adımı FARKLI bir")
            print("    adım (RM derin diz sürücülü). 'RM'den küçük' ile")
            print("    'ölçülemez' aynı şey değildir — eşik, bounce'ın KENDİ")
            print("    eğitmen-ayrışmasından türemeli, başka adımdan değil.")
    print()
    print("NOT: bu araç pencerenin bounce mu başka bir hareket mi olduğunu")
    print("söyleyemez — yalnız diz sinyalinin BÜYÜKLÜĞÜNÜ. Kimlik sorusu")
    print("(l3r4bPhikGQ bounce mu criss-cross mu) ayrı ve ancak doğru pencere")
    print("bulunduktan SONRA sorulabilir.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
