#!/usr/bin/env python3
"""Diz-sürücülü ÇÖKÜŞ SAYICI — harmonik BİRİM sorusunu doğrudan kesen ölçü.

Neden bu araç var
-----------------
`hh_bounce` havuzu iki harmonik aileye ayrıldı: KISA {0,68 · 0,71s} ↔ UZUN
{1,27 · 1,37 · 1,70s}, dört çift 1,79-2,01× (C-123). `build_reference`'ın
harmonik kapısı haklı olarak durdurdu: faz ekseni ancak her take AYNI çevrimde
kesilmişse take'ler arasında aynı şeyi anlatır.

Kapı kendi çaresini adlandırıyor ("`measure_tempo` ile yarım çevrime
kilitlenenleri ele") ama çare ÖLÇÜLDÜ ve KAPALI çıktı: `measure_tempo` 5 take'in
2'sinde `no_peak`, 2'sinde `prepare_take` ile 2-3× çelişiyor. Hakemin hakeme
ihtiyacı vardı.

Bu araç hakemi adımın KENDİ faz-sürücüsünden alır (M-F-195/M-F-226): soru
"periyot kaç saniye" değil, **"prepare_take'in atadığı çevrimin içinde KAÇ diz
çöküşü var"**. Bir çöküş varsa take tek-birimde, iki çöküş varsa çift-birimde
kesilmiştir. Bu, periyot kestiricilerinin anlaşamadığı yerde anlaşma
gerektirmeyen bir ölçüdür — sayım, kestirim değil.

NE YAPMAZ (M-F-198, ve bu deponun kendi yarası)
------------------------------------------------
**Pencere OPTİMİZASYONU yapmaz.** `probe_knee_windows` "en güçlü pencereyi bul"
diye kurulmuştu ve iki kez fizyolojik olarak imkânsız sayı üretti (genlik 173°,
düşüş 3031°/s) çünkü tek bir istatistikle en-iyi-pencere aramak, izleme
dropout'u olan videoda hareketi değil EN KÖTÜ İZLENEN yeri bulur. Burada arama
YOK: olaylar TÜM take üzerinde tespit edilir, ve ikinci bir rapor
`prepare_take`'in ZATEN ATADIĞI segmentle sınırlanır. O segment benim seçimim
değil, hattın seçimi — kullanmak arama değil, verilmiş girdiyi okumaktır.

Parametrelerin kaynağı (M-F-94 / M-F-226 şart 1)
------------------------------------------------
Hiçbir eşik icat EDİLMEDİ:

  top giriş açısı >168°      <- hh_bounce.json faz `top`          [CONFIG]
  hız eşiği     >=40 deg/s   <- hh_bounce.json faz `drop`/`rise`  [CONFIG]
  çöküş = yerel minimum      <- hh_bounce.json faz `bottom`       [CONFIG]
  min çöküş derinliği 6,0°   <- build_reference.MIN_TOLERANCE_DEG [HAT SABİTİ]
      Gerekçe sert kural: bir karar ölçüsü kendi gürültü tabanının ALTINDA
      soru soramaz. Tabandan sığ bir çukur "çöküş" diye sayılamaz.
  1x / 2x bantları           <- build_reference harmonik kapısı   [ATIFLI]
      Kapı 2x'i [1,7 - 2,3] diye tanımlıyor (sabit olarak dışa vermiyor, o
      yüzden burada İSİMLE atıfla yeniden yazıldı); 1x bandı aynı yapının
      aynası: [0,7 - 1,3].

Açı tanımı `prepare_take`'ten İÇE AKTARILIR, yeniden yazılmaz (M-F-03).

RAPOR-ÖNCE (M-F-196/M-F-226 şart 6)
------------------------------------
Çıktı bir RAPORDUR: take başına çöküş sayısı + aralık + verdikt
(`one-dip` / `two-dip` / `indeterminate`) + kanıt. Bu araç hiçbir take'i
yeniden sınıflandırmaz, hiçbir artefakt yazmaz, hiçbir config değiştirmez.
Yeniden sınıflandırma `decisions.json` üzerinden, take başına İSİMLİ kanıtla
yapılır (M-F-47) — ve o kanıt tam olarak buradaki çöküş sayımlarıdır.

  python3 tools/probe_knee_dips.py --self-test
  python3 tools/probe_knee_dips.py --step hh_bounce ID [ID ...]
  python3 tools/probe_knee_dips.py --step hh_bounce --prepared DIR ID [ID ...]
"""
from __future__ import annotations

import argparse
import json
import math
import statistics as st
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# TEK KAYNAK: açı tanımı ve config okuyucuları yeniden yazılmaz (M-F-03).
from build_reference import MIN_TOLERANCE_DEG  # noqa: E402
from probe_knee_windows import (  # noqa: E402
    _median3,
    knee_mean_series,
    phase_thresholds,
    step_config,
)

# build_reference harmonik kapısının bandı. Kapı bunu sabit olarak dışa
# vermiyor (satır içi yazılı), o yüzden ATIFLA yeniden yazıldı — sürüklenirse
# aşağıdaki drift notu ısırır.
HARMONIC_2X = (1.7, 2.3)
HARMONIC_1X = (0.7, 1.3)


# ---------------------------------------------------------------------------
# ÇEKİRDEK: saf fonksiyon. Video yok, dosya yok — sentetik doğrulama bu yüzden
# mümkün (sahte girdi ARIZA KİPİNİ taklit edebilsin diye NaN de kabul edilir).
# ---------------------------------------------------------------------------
def _runs(series: list[float]) -> list[tuple[int, list[float]]]:
    """NaN'lerle bölünmüş kesintisiz geçerli parçalar. NaN DOLDURULMAZ:
    görünmeyen kareyi interpole etmek, görünürlük kapısının engellemek için
    var olduğu şeydir."""
    out, start, buf = [], 0, []
    for i, v in enumerate(series):
        if v != v:
            if buf:
                out.append((start, buf))
            buf, start = [], i + 1
        else:
            if not buf:
                start = i
            buf.append(v)
    if buf:
        out.append((start, buf))
    return out


def _extrema(xs: list[float]) -> list[tuple[int, float, str]]:
    """Yön değişimlerinden alternatif min/max dizisi — UÇLAR DAHİL.

    İlk sürüm baştaki ucu KAYBEDİYORDU (yön henüz kurulmamışken ilk nokta
    hiç eklenmiyordu), bu yüzden her seri TAM BİR ÇÖKÜŞ EKSİK sayılıyordu.
    Sentetik doğrulama yakaladı (4/8/12 çöküş -> 3/7/11): bilinen-cevaplı
    girdi olmasaydı bu hata gerçek take'lerde 1 fark olarak geçer ve birim
    hükmünü sessizce bozardı."""
    n = len(xs)
    if n < 3:
        return []
    # Aynı değerli düzlükleri tek noktaya indir (yön tanımsız kalmasın).
    pts: list[tuple[int, float]] = [(0, xs[0])]
    for i in range(1, n):
        if xs[i] != pts[-1][1]:
            pts.append((i, xs[i]))
    if len(pts) < 3:
        return []
    ext: list[tuple[int, float, str]] = []
    first_up = pts[1][1] > pts[0][1]
    ext.append((pts[0][0], pts[0][1], "min" if first_up else "max"))
    for k in range(1, len(pts) - 1):
        up_in = pts[k][1] > pts[k - 1][1]
        up_out = pts[k + 1][1] > pts[k][1]
        if up_in != up_out:
            ext.append((pts[k][0], pts[k][1], "max" if up_in else "min"))
    last_up = pts[-1][1] > pts[-2][1]
    ext.append((pts[-1][0], pts[-1][1], "max" if last_up else "min"))
    return ext


def _prune(ext: list[tuple[int, float, str]], min_depth: float):
    """Belirginliği eşiğin altındaki salınımları eler (tepe-kalıcılığı).

    Gürültü kırışıklığı bir çöküş DEĞİLDİR; eşik uydurulmadı, hattın kendi
    gürültü tabanı (MIN_TOLERANCE_DEG)."""
    e = list(ext)
    changed = True
    while changed and len(e) >= 3:
        changed = False
        for i in range(1, len(e) - 1):
            if abs(e[i][1] - e[i - 1][1]) < min_depth and \
               abs(e[i][1] - e[i + 1][1]) < min_depth:
                # i ve komşularından biri sahte salınım: ikisini de at.
                del e[i:i + 2]
                changed = True
                break
    return e


def _peak_rate(xs: list[float], a: int, b: int, fps: float) -> float:
    """a..b arasındaki en yüksek ANLIK hız (deg/s), mutlak.

    Config faz makinesi "anlık hız eşiği aşınca fazına gir" diyor; ortalama
    hız farklı bir soruya cevap verir. Medyan-filtreli seride hesaplanır."""
    best = 0.0
    for i in range(a + 1, b + 1):
        best = max(best, abs(xs[i] - xs[i - 1]) * fps)
    return best


def detect_dips(series: list[float], fps: float, *,
                top_deg: float | None, rate_deg_s: float | None,
                min_depth: float = MIN_TOLERANCE_DEG) -> dict:
    """Serideki diz ÇÖKÜŞ olaylarını bul. Saf: girdi seri, çıktı rapor."""
    dips: list[dict] = []
    for offset, run in _runs(series):
        sm = _median3(run)
        ext = _prune(_extrema(sm), min_depth)
        for i in range(1, len(ext) - 1):
            if ext[i][2] != "min":
                continue
            (ai, av, _), (bi, bv, _), (ci, cv, _) = ext[i - 1], ext[i], ext[i + 1]
            depth_in, depth_out = av - bv, cv - bv
            if min(depth_in, depth_out) < min_depth:
                continue
            down = _peak_rate(sm, ai, bi, fps)
            up = _peak_rate(sm, bi, ci, fps)
            # Config'in KENDİ hız kapısı. Eşik yoksa hüküm de yok.
            if rate_deg_s is not None and min(down, up) < rate_deg_s:
                continue
            dips.append({
                "frame": offset + bi,
                "seconds": round((offset + bi) / fps, 3),
                "bottomDeg": round(bv, 1),
                "precedingTopDeg": round(av, 1),
                "depthInDeg": round(depth_in, 1),
                "depthOutDeg": round(depth_out, 1),
                "peakDownRate": round(down, 1),
                "peakUpRate": round(up, 1),
                # Config'in `top` kapısı AYRI raporlanır, FİLTRE DEĞİL:
                # sağlanmaması "çöküş yok" değil "tam ekstansiyona
                # çıkılmıyor" demektir (ön-kayıtlı dördüncü çıkış).
                "topQualified": (None if top_deg is None else av >= top_deg),
            })
    dips.sort(key=lambda d: d["frame"])
    gaps = [round(dips[i + 1]["seconds"] - dips[i]["seconds"], 3)
            for i in range(len(dips) - 1)]
    valid = sum(1 for v in series if v == v)
    # KARE-ARASI ARTIK: ham (filtrelenmemiş) seride ardışık fark. Eşik DEĞİL,
    # tanı. Gürültü sınırı sentetik olarak ölçüldü (self-test 3b) ve gerçek
    # take'in artığı O SINIRLA BİRLİKTE okunur — "ölçü bu veride güvenli mi"
    # sorusu ancak böyle cevaplanır.
    diffs = []
    for _o, run in _runs(series):
        diffs.extend(abs(run[i] - run[i - 1]) for i in range(1, len(run)))
    diffs.sort()
    return {
        "dipCount": len(dips),
        "dips": dips,
        "interDipSeconds": gaps,
        "medianInterDipSeconds": (round(st.median(gaps), 3) if gaps else None),
        "topQualifiedCount": sum(1 for d in dips if d["topQualified"]),
        "coverage": round(valid / len(series), 3) if series else 0.0,
        "medianAbsDiffDeg": (round(diffs[len(diffs) // 2], 2) if diffs else None),
        "p95AbsDiffDeg": (round(diffs[int(0.95 * (len(diffs) - 1))], 2)
                          if diffs else None),
    }


def classify_unit(assigned_period: float | None,
                  median_gap: float | None) -> tuple[str, float | None]:
    """Atanan çevrim KAÇ çöküş taşıyor? Bantlar build_reference kapısından."""
    if not assigned_period or not median_gap or median_gap <= 0:
        return "indeterminate", None
    ratio = assigned_period / median_gap
    if HARMONIC_1X[0] <= ratio <= HARMONIC_1X[1]:
        return "one-dip", ratio
    if HARMONIC_2X[0] <= ratio <= HARMONIC_2X[1]:
        return "two-dip", ratio
    return "indeterminate", ratio


# ---------------------------------------------------------------------------
# (a) SENTETİK DOĞRULAMA — bilinen cevaplı girdi, hüküm ÖNCESİ
# ---------------------------------------------------------------------------
def _synth(n_dips: int, fps: float, seconds: float, depth: float,
           baseline: float = 172.0, noise: float = 0.0,
           dropout: tuple[float, float] | None = None) -> list[float]:
    """Bilinen sayıda çöküş taşıyan sentetik diz serisi."""
    n = int(fps * seconds)
    out = []
    rnd = 12345
    for i in range(n):
        t = i / fps
        phase = 2 * math.pi * n_dips * t / seconds
        v = baseline - depth * (0.5 - 0.5 * math.cos(phase))
        if noise:
            rnd = (1103515245 * rnd + 12345) % (2 ** 31)
            v += noise * ((rnd / (2 ** 31)) - 0.5) * 2
        out.append(v)
    if dropout:
        a, b = int(dropout[0] * fps), int(dropout[1] * fps)
        for i in range(max(0, a), min(n, b)):
            out[i] = float("nan")
    return out


def self_test() -> int:
    fps, fails = 30.0, 0

    def check(label, cond, detail=""):
        nonlocal fails
        print(f"  {'✓' if cond else '✗'} {label}{('  ' + detail) if detail else ''}")
        if not cond:
            fails += 1

    print("probe_knee_dips — sentetik doğrulama (bilinen cevaplı girdi)\n")
    kw = dict(top_deg=168.0, rate_deg_s=40.0)

    # 1. Bilinen çöküş sayısı, birden çok değerde.
    for k in (4, 8, 12):
        r = detect_dips(_synth(k, fps, 8.0, depth=40.0), fps, **kw)
        check(f"{k} çöküş sayıldı", r["dipCount"] == k, f"bulunan={r['dipCount']}")

    # 2. ÇÖKÜŞSÜZ kontrol — düz sinyal. Bu testin kırılabilirliği önemli:
    #    her zaman >0 döndüren bir sayıcı burada DÜŞER.
    flat = [172.0] * int(fps * 8)
    r0 = detect_dips(flat, fps, **kw)
    check("düz sinyalde çöküş YOK", r0["dipCount"] == 0, f"bulunan={r0['dipCount']}")

    # 3. Gürültülü ama çöküşsüz — TABAN ALTI gürültü çöküş sayılmamalı.
    #    ±2° = 4° tepe-tepe < 6° taban.
    rn = detect_dips(_synth(0, fps, 8.0, depth=0.0, noise=2.0), fps, **kw)
    check("gürültü (±2° = 4° tepe-tepe, TABAN ALTI) sayılmıyor",
          rn["dipCount"] == 0, f"bulunan={rn['dipCount']}")

    # 3b. GÜRÜLTÜ SINIRI — İDDİA değil ÖLÇÜM, ve İKİ YÖNLÜ kanarya.
    #     İlk yazdığım test "±4° sahte çöküş imal eder" diyordu; ölçtüm,
    #     ETMİYOR (0). Yani ölçü iddia ettiğimden sağlam çıktı — testi
    #     iddiama göre değil ölçüme göre yazıyorum. Ölçülen sınır:
    #       ±2°/±4° -> 0 sahte  ·  ±6° -> 13  ·  ±8° -> 20  ·  ±20° -> 37
    #     Kanarya İKİ yöne de bakıyor: sağlamlık kaybolursa DÜŞER (alt sınır),
    #     ve kırılma noktası kaybolursa da DÜŞER (üst sınır) — çünkü o zaman
    #     eleme fazla agresifleşmiş, yani gerçek çöküşleri de yiyor olabilir.
    rn4 = detect_dips(_synth(0, fps, 8.0, depth=0.0, noise=4.0), fps, **kw)
    check("±4° (8° tepe-tepe) gürültü sahte çöküş ÜRETMİYOR",
          rn4["dipCount"] == 0, f"bulunan={rn4['dipCount']}")
    rn6 = detect_dips(_synth(0, fps, 8.0, depth=0.0, noise=6.0), fps, **kw)
    check("SINIR ÖLÇÜLDÜ: ±6° (12° tepe-tepe) gürültü sahte çöküş ÜRETİR",
          rn6["dipCount"] > 0,
          f"bulunan={rn6['dipCount']} — gizlenmiyor; gerçek take'lerin "
          f"kare-arası artığı bu sınırla birlikte OKUNMALI")

    # 4. Gürültülü AMA gerçek çöküşlü — sinyal gürültüde kaybolmamalı.
    rs = detect_dips(_synth(6, fps, 8.0, depth=40.0, noise=3.0), fps, **kw)
    check("gürültüde 6 gerçek çöküş hâlâ bulunuyor", rs["dipCount"] == 6,
          f"bulunan={rs['dipCount']}")

    # 5. DROPOUT (ARIZA KİPİ taklidi, C-115): NaN boşluğu. Sahte girdi imzayı
    #    değil arıza kipini taklit etmeli — dolayısıyla NaN, 0.0 değil.
    rd = detect_dips(_synth(8, fps, 8.0, depth=40.0, dropout=(3.0, 4.0)), fps, **kw)
    check("dropout çökertmiyor, kapsam raporlanıyor",
          rd["dipCount"] > 0 and rd["coverage"] < 1.0,
          f"çöküş={rd['dipCount']} kapsam={rd['coverage']}")
    check("dropout'ta uydurulmuş çöküş YOK (<=8)", rd["dipCount"] <= 8,
          f"bulunan={rd['dipCount']}")

    # 6. Sığ çöküş — taban altı, sayılmamalı (sert kural).
    rsh = detect_dips(_synth(6, fps, 8.0, depth=4.0), fps, **kw)
    check("4° derinlik (taban altı) sayılmıyor", rsh["dipCount"] == 0,
          f"bulunan={rsh['dipCount']}")

    # 7. `top` kapısı AYRI raporlanıyor, filtre değil: alçak taban çizgisi.
    rt = detect_dips(_synth(6, fps, 8.0, depth=40.0, baseline=150.0), fps, **kw)
    check("top sağlanmasa da çöküş SAYILIYOR (kapı ayrı)",
          rt["dipCount"] == 6 and rt["topQualifiedCount"] == 0,
          f"çöküş={rt['dipCount']} topQualified={rt['topQualifiedCount']}")

    # 8. BİRİM sınıflandırıcı — bilinen oranlar.
    check("atanan periyot = aralık -> one-dip",
          classify_unit(1.0, 1.0)[0] == "one-dip")
    check("atanan periyot = 2x aralık -> two-dip",
          classify_unit(2.0, 1.0)[0] == "two-dip")
    check("atanan periyot = 1,5x aralık -> indeterminate",
          classify_unit(1.5, 1.0)[0] == "indeterminate")
    check("aralık yok -> indeterminate",
          classify_unit(1.0, None)[0] == "indeterminate")

    print()
    if fails:
        print(f"SELF-TEST FAILED ({fails})")
        return 1
    print("SELF-TEST OK")
    return 0


# ---------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--step")
    ap.add_argument("videos", nargs="*")
    ap.add_argument("--prepared", help="prepare_take çıktı dizini (segment "
                                       "ve atanan periyot buradan OKUNUR)")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    if not args.step or not args.videos:
        ap.print_help()
        return 1

    cfg = step_config(args.step)
    top_deg, rate = phase_thresholds(cfg)
    print(f"adım: {args.step} — KENDİ faz eşikleri: top >{top_deg}° · "
          f"hız >={rate}°/s · min derinlik {MIN_TOLERANCE_DEG}° "
          f"(MIN_TOLERANCE_DEG)")
    print(f"birim bantları (build_reference harmonik kapısından): "
          f"1x={HARMONIC_1X} · 2x={HARMONIC_2X}\n")

    prep_dir = Path(args.prepared) if args.prepared else None
    rows = []
    for vid in args.videos:
        try:
            series, fps = knee_mean_series(vid)
        except SystemExit as e:
            print(f"── {vid} ── atlandı: {e}\n")
            continue

        whole = detect_dips(series, fps, top_deg=top_deg, rate_deg_s=rate)

        seg_report, assigned, verdict, ratio = None, None, "indeterminate", None
        if prep_dir and (prep_dir / f"{vid}.json").exists():
            p = json.loads((prep_dir / f"{vid}.json").read_text(encoding="utf-8"))
            seg = p.get("segment") or {}
            assigned = p.get("periodSeconds")
            a, b = seg.get("startFrame"), seg.get("endFrame")
            if a is not None and b is not None:
                seg_report = detect_dips(series[a:b], fps,
                                         top_deg=top_deg, rate_deg_s=rate)
                verdict, ratio = classify_unit(
                    assigned, seg_report["medianInterDipSeconds"])

        print(f"── {vid} ──")
        print(f"   TÜM TAKE : {whole['dipCount']} çöküş · "
              f"ortanca aralık {whole['medianInterDipSeconds']}s · "
              f"topQualified {whole['topQualifiedCount']}/{whole['dipCount']} · "
              f"kapsam {whole['coverage']}")
        if seg_report is not None:
            print(f"   SEGMENT  : {seg_report['dipCount']} çöküş · "
                  f"ortanca aralık {seg_report['medianInterDipSeconds']}s · "
                  f"topQualified {seg_report['topQualifiedCount']}/"
                  f"{seg_report['dipCount']}")
            print(f"   atanan periyot {assigned}s / çöküş aralığı "
                  f"{seg_report['medianInterDipSeconds']}s = "
                  f"{('%.2f' % ratio) if ratio else '—'}  ->  **{verdict}**")
        else:
            print("   SEGMENT  : prepared dosyası yok — birim hükmü VERİLEMEZ")
        print()
        rows.append({"videoId": vid, "verdict": verdict, "ratio": ratio,
                     "assignedPeriod": assigned,
                     "segmentDips": seg_report["dipCount"] if seg_report else None,
                     "segmentGap": (seg_report["medianInterDipSeconds"]
                                    if seg_report else None),
                     "wholeDips": whole["dipCount"],
                     "topQualified": whole["topQualifiedCount"]})

    print(f"{'video':<15}{'atanan':>8}{'aralık':>8}{'oran':>7}  verdikt")
    for r in rows:
        print(f"{r['videoId']:<15}{str(r['assignedPeriod']):>8}"
              f"{str(r['segmentGap']):>8}"
              f"{('%.2f' % r['ratio']) if r['ratio'] else '—':>7}  "
              f"{r['verdict']}")
    tally: dict[str, int] = {}
    for r in rows:
        tally[r["verdict"]] = tally.get(r["verdict"], 0) + 1
    print(f"\nsayım: {tally}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
