#!/usr/bin/env python3
"""ŞABLON VARLIK DENETİMİ — ikon/açılış-ekranı GERÇEKTEN değişti mi, yoksa
Flutter'ın stok görseli mi duruyor? (H-56, 2026-08-16, Ostinato'nun
validate_template_assets.py'si şema alınarak — O-158)

DECLARED_DEFAULT_MD5: `flutter create` ile üretilen TAZE bir referans
projeden (Flutter 3.41.1 — bu makinedeki `flutter --version` ile
DOĞRULANDI, Ostinato'nunkiyle birebir aynı sürüm) ÖLÇÜLDÜ, uydurulmadı.
Depodaki dosya bu hash'lerden BİRİNE eşitse hâlâ şablon demektir.

DURUM (ölçüldü, H-56/C-296): Choreia'nın 25/25 ikon/açılış varlığı ŞU AN
hâlâ stok — sıfır özelleştirme. İLK YAZILIŞTA bu araç KASITLI OLARAK
`tool/gates.sh`e bağlanmamıştı (Ostinato'nunki `tools/run_gates.sh`e
bağlı olduğu HALDE — bu yanlış gerekçelendirilmiş bir varsayımdı, ölçmeden
"muhtemelen bağlı değildir" denmişti). Orkestratör düzeltti: BAĞLANMAMIŞ
bir kapı koşmayan bir kapıdır (H-48/L-178 sınıfı — okuyucusu/çağıranı
olmayan bir kural). Şimdi BAĞLI, ama H-50'nin MUTABAKAT KAYDI deseniyle
(`RECONCILED_STOCK_2026_08_16`, aşağıda) — muafiyet değil, adlı+tarihli
bir bekleme kaydı: kapı KOŞAR, bilinen 25 varlık için kırmızı YANMAZ, ama
KAYITTA OLMAYAN yeni bir stok varlık YİNE öter. D8 gerçek varlıkları
bağlandığında kayıttan tek tek çıkarılmalı.
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DECLARED_DEFAULT_MD5 = {
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": "c785f8932297af4acd5f5ccb7630f01c",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png": "a2f8558fb1d42514111fbbb19fb67314",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png": "2247a840b6ee72b8a069208af170e5b1",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png": "1b3b1538136316263c7092951e923e9d",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png": "be8887071dd7ec39cb754d236aa9584f",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png": "043119ef4faa026ff82bd03f241e5338",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png": "2b1452c4c1bda6177b4fbbb832df217f",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png": "2247a840b6ee72b8a069208af170e5b1",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png": "8245359312aea1b0d2412f79a07b0ca5",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png": "5b3c0902200ce596e9848f22e1f0fe0e",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png": "5b3c0902200ce596e9848f22e1f0fe0e",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png": "e419d22a37bc40ba185aca1acb6d4ac6",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png": "36c0d7a7132bdde18898ffdfcfcdc4d2",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png": "643842917530acf4c5159ae851b0baf2",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png": "665cb5e3c5729da6d639d26eff47a503",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png": "978c1bee49d7ad5fc1a4d81099b13e18",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png": "978c1bee49d7ad5fc1a4d81099b13e18",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png": "978c1bee49d7ad5fc1a4d81099b13e18",
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": "6270344430679711b81476e29878caa7",
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": "13e9c72ec37fac220397aa819fa1ef2d",
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": "a0a8db5985280b3679d99a820ae2db79",
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": "afe1b655b9f32da22f9a4301bb8e6ba8",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": "57838d52c318faff743130c3fcfae0c6",
    "android/app/src/main/res/drawable/launch_background.xml": "79c59c987bd2e693cd741ec3035ef383",
    "android/app/src/main/res/drawable-v21/launch_background.xml": "ab00f2bfdce1a5187d1ba31e9e68b921",
}

#: iOS'un GERÇEK açılış ekranı `LaunchScreen.storyboard`dır — `LaunchImage`
#: yalnız o storyboard'un REFERANS ettiği bir varlıktır. Storyboard'un
#: KENDİ `backgroundColor`ı hâlâ saf beyazsa, LaunchImage değişmiş olsa
#: bile açılış ekranı beyaz zeminle açılırdı — bu yüzden ayrı, alan-bazlı
#: bir kontrol (MD5 değil, XML küçük ve insan-okur).
STORYBOARD = "ios/Runner/Base.lproj/LaunchScreen.storyboard"
STORYBOARD_STILL_WHITE = 'red="1" green="1" blue="1" alpha="1"'


def measure() -> dict:
    current = {}
    for rel in DECLARED_DEFAULT_MD5:
        p = ROOT / rel
        if not p.exists():
            current[rel] = None
            continue
        current[rel] = hashlib.md5(p.read_bytes()).hexdigest()
    return current


def find_still_default(declared: dict, current: dict) -> list[str]:
    return [rel for rel, md5 in current.items()
            if md5 is not None and md5 == declared.get(rel)]


def find_missing(current: dict) -> list[str]:
    return [rel for rel, md5 in current.items() if md5 is None]


def storyboard_still_white() -> bool:
    p = ROOT / STORYBOARD
    return p.exists() and STORYBOARD_STILL_WHITE in p.read_text(encoding="utf-8")


# MUTABAKAT KAYDI (H-50 deseni — Ostinato'nun RETENTION_WRITERS_RECONCILED'i),
# MUAFİYET DEĞİL. Orkestratör kararı (H-56 devamı, 2026-08-16): kapı BAĞLANIR
# ama şu ANDA BİLİNEN stok varlıklar adıyla+tarihiyle kayda geçirilir, kapı
# yalnız BU listedeki dosyaları/kontrolü muaf sayar — BAŞKA HİÇBİR VARLIĞI
# DEĞİL. Bu yüzden LİTERAL, elle yazılmış bir küme — `DECLARED_DEFAULT_MD5`in
# anahtarlarından TÜRETİLMEZ; türetilseydi bu kayıt hiçbir şeyi taşımaz,
# gelecekte eklenecek her yeni dosyayı da sessizce muaf sayardı.
#
# KAPANIŞ YOLU: D8 (mor zemin + dans-figürü silüeti) gerçek varlıkları
# bağlandığında, İLGİLİ dosya(lar) bu kümeden TEK TEK çıkarılır — küme
# küçüldükçe kapının kapsamı GENİŞLER, tersi değil. `C-296`da ölçülen bu
# tam liste; yeni bir dosya BU LİSTEDE OLMADAN stoksa (örn. biri yanlışlıkla
# gerçek bir varlığı stoka geri çevirirse) kapı YİNE öter.
RECONCILED_STOCK_2026_08_16: frozenset[str] = frozenset({
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png",
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    "android/app/src/main/res/drawable/launch_background.xml",
    "android/app/src/main/res/drawable-v21/launch_background.xml",
})
RECONCILED_STORYBOARD_WHITE_2026_08_16 = True


def main() -> int:
    current = measure()
    still_default = find_still_default(DECLARED_DEFAULT_MD5, current)
    missing = find_missing(current)
    changed = len(current) - len(still_default) - len(missing)

    unreconciled_stock = [r for r in still_default
                           if r not in RECONCILED_STOCK_2026_08_16]
    reconciled_hits = [r for r in still_default
                        if r in RECONCILED_STOCK_2026_08_16]

    violations = []
    if unreconciled_stock:
        violations.append(
            f"[şablon, KAYITLI DEĞİL] {len(unreconciled_stock)} varlık HÂLÂ "
            f"Flutter'ın stok görseliyle birebir aynı VE mutabakat kaydında "
            f"yok — yeni bir gerileme: " + ", ".join(unreconciled_stock))
    if missing:
        violations.append(
            f"[eksik] {len(missing)} beklenen dosya YOK: " + ", ".join(missing))
    if storyboard_still_white() and not RECONCILED_STORYBOARD_WHITE_2026_08_16:
        violations.append(
            f"[açılış zemini] {STORYBOARD} hâlâ saf beyaz "
            f"(`{STORYBOARD_STILL_WHITE}`) — LaunchImage değişmiş olsa "
            f"bile açılış ekranı beyaz zeminle açılır")

    if violations:
        print(f"⛔ {len(violations)} ŞABLON-VARLIK İHLALİ (mutabakat kaydı "
              f"dışında):")
        for v in violations:
            print(f"   - {v}")
        print(f"   ⚠️ DECLARED_DEFAULT_MD5 Flutter 3.41.1'den ölçüldü — SDK "
              f"yükseldiyse şablonun kendisi değişmiş olabilir, bu durumda "
              f"burada YANLIŞ-NEGATİF (gerçekte değişmiş bir varlık hâlâ "
              f"'şablon' sanılabilir) ihtimali var; `flutter --version` "
              f"kontrol edilmeli.")
        return 1

    if reconciled_hits or (storyboard_still_white() and RECONCILED_STORYBOARD_WHITE_2026_08_16):
        print(f"⚠️ MUTABAKAT KAYDI YÜRÜRLÜKTE (D8, C-296, 2026-08-16): "
              f"{len(reconciled_hits)} varlık + açılış zemini hâlâ stok, "
              f"KAYITLI ve İZLENİYOR — kapı bu dosyalar İÇİN kırmızı YANMAZ. "
              f"D8 gerçek varlıkları bağlandığında bu kayıttan tek tek "
              f"çıkarılmalı, yoksa bir regresyon sessizce kalıcılaşır.")

    print(f"✅ şablon-varlık denetimi TEMİZ (kayıtlı istisnalar dışında) — "
          f"{changed}/{len(current)} varlık stok Flutter görsellerinden "
          f"GERÇEKTEN farklı (MD5 karşılaştırmalı)")
    return 0


def selftest() -> int:
    """Karşılaştırma MANTIĞI sentetik veriyle sınanır — gerçek dosyalara
    dokunmadan (O-116 ilkesi: bugünkü depo durumuna bağımlı olma)."""
    declared = {"a.png": "AAA", "b.png": "BBB", "c.xml": "CCC"}

    still_stock = {"a.png": "AAA", "b.png": "changed", "c.xml": "CCC"}
    hits = find_still_default(declared, still_stock)
    assert hits == ["a.png", "c.xml"], hits

    all_changed = {"a.png": "x1", "b.png": "x2", "c.xml": "x3"}
    assert find_still_default(declared, all_changed) == []

    with_missing = {"a.png": None, "b.png": "x2", "c.xml": "x3"}
    assert find_missing(with_missing) == ["a.png"]
    assert find_still_default(declared, with_missing) == []

    # MUTABAKAT KAYDI mantığı: kayıtlı bir stok isabetinin kırmızı ÜRETMEMESİ,
    # KAYITSIZ bir isabetin ürettiği (H-56 sonrası eklendi). `still_stock`
    # yukarıda a.png+c.xml'i stok döndürüyordu — burada sentetik bir kayıt
    # kümesiyle ikisi AYRIŞTIRILIYOR: biri kayıtlı (susmalı), biri değil
    # (ötmeli). Gerçek kodun `main()`daki filtre satırının aynısı, izole.
    reconciled = frozenset({"a.png"})
    still_default_hits = find_still_default(declared, still_stock)
    unreconciled = [r for r in still_default_hits if r not in reconciled]
    reconciled_hits = [r for r in still_default_hits if r in reconciled]
    assert unreconciled == ["c.xml"], unreconciled
    assert reconciled_hits == ["a.png"], reconciled_hits

    print("✅ şablon-varlık öz-testi GEÇTİ — hâlâ-stok/değişmiş/eksik/"
          "mutabakat-kaydı sınıflandırması sentetik veriyle doğrulandı")
    return 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else main())
