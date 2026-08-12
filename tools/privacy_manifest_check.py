#!/usr/bin/env python3
"""GİZLİLİK MANİFESTİ KAPISI — A8 (C-266).

NİYE VAR
--------
`PrivacyInfo.xcprivacy` App Store'da zorunlu; yokluğu bir RET sebebi. Ama
ölçütün A8'i dosyanın VARLIĞINI sormuyor, ***PAKETTE olmasını*** soruyor:

    ***Bir manifest, Xcode projesine BAĞLI DEĞİLSE pakete GİRMEZ.***

Dosya depoda durur, `git` mutlu, kimse fark etmez — ve mağaza yine reddeder.
Bu yüzden kapı DÖRT atfın dördünü de arar: `PBXBuildFile` · `PBXFileReference` ·
Runner grubu çocuğu · `Resources` fazı. (Bu yarısı Lissom'un `L-288` kapısından
ÖLÇÜLEREK uyarlandı — okundu, kopyalanmadı.)

⭐ VE CHOREIA'NIN EKLEDİĞİ İKİNCİ YÖN — sebebi ölçüldü
------------------------------------------------------
Choreia'nın manifestinde `NSPrivacyAccessedAPITypes` **BOŞ**. Boş bir dizi,
kapı yalnız "anahtar var mı" diye baksaydı ***bir varsayım*** olurdu ve
sessizce bayatlardı: yarın `AppDelegate.swift`e bir `UserDefaults` girer,
manifest boş kalır, ve *hiçbir kapı ötmez.*

    ***BİR BEYANIN BOŞ OLMASI, ONU DOĞRULAMAKTAN MUAF TUTMAZ —
       BOŞLUK DA BİR İDDİADIR.***

⇒ Kapı, Runner hedefinin KENDİ kaynaklarını her koşumda tarar ve gerekçe
gerektiren bir API çağrısı bulup manifestte karşılığını bulamazsa **kırmızı**
yanar.

⚠️ ASİMETRİ, KASITLI VE SEBEPLİ: eksik-beyan **bloklar**, fazla-beyan
**yalnız adıyla yazılır**. Sebep: bu tarayıcı yalnız ObjC/Swift kaynağını
görür; Dart tarafı (`FileFirstRunFlag`, `materialisePoseModel`) ona
GÖRÜNMEZ. Fazla-beyanı kırmızı yakmak, göremediği bir çağrıyı "yok" saymak
olurdu. *Bir tarayıcının hükmü, gördüğü yüzey kadardır.*

⚠️ Vakum koruması: taranacak kaynak dosya HİÇ bulunamazsa kapı öter —
*boş bir sayaç sıfır değildir.*

⛔ `.lower()` / `casefold()` YOK: eşleşen şeyler Swift/ObjC **tanımlayıcıları**
ve zaten harf-duyarlı. Türkçe katlama burada yanlış olurdu, gereksiz de.
"""
from __future__ import annotations

import plistlib
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "ios" / "Runner" / "PrivacyInfo.xcprivacy"
PBXPROJ = REPO / "ios" / "Runner.xcodeproj" / "project.pbxproj"
RUNNER_SRC = REPO / "ios" / "Runner"
SRC_SUFFIXES = (".swift", ".m", ".mm", ".h")

REQUIRED_KEYS = (
    "NSPrivacyTracking",
    "NSPrivacyTrackingDomains",
    "NSPrivacyCollectedDataTypes",
    "NSPrivacyAccessedAPITypes",
)

# Apple'ın "gerekçe gerektiren API" listesinden, bir uygulamanın KENDİ iOS
# hedefinden erişilebilen çağrılar. Dizgeler tahmin değil: Apple'ın kategori
# tanımlarındaki sembol adları.
API_SYMBOLS: dict[str, tuple[str, ...]] = {
    "NSPrivacyAccessedAPICategoryUserDefaults": (
        "UserDefaults",
        "NSUserDefaults",
    ),
    "NSPrivacyAccessedAPICategoryFileTimestamp": (
        "creationDate",
        "modificationDate",
        "fileModificationDate",
        "contentModificationDateKey",
        "creationDateKey",
        "getattrlist",
        "getattrlistbulk",
        "fgetattrlist",
        "getattrlistat",
    ),
    "NSPrivacyAccessedAPICategorySystemBootTime": (
        "systemUptime",
        "mach_absolute_time",
    ),
    "NSPrivacyAccessedAPICategoryDiskSpace": (
        "volumeAvailableCapacityKey",
        "volumeAvailableCapacityForImportantUsageKey",
        "volumeAvailableCapacityForOpportunisticUsageKey",
        "volumeTotalCapacityKey",
        "systemFreeSize",
        "systemSize",
        "statfs",
        "statvfs",
    ),
    "NSPrivacyAccessedAPICategoryActiveKeyboards": (
        "activeInputModes",
    ),
}


def scan_sources(sources: dict[str, str]) -> dict[str, str]:
    """Kaynakta geçen gerekçeli-API kategorileri → bulunduğu sembol+dosya."""
    found: dict[str, str] = {}
    for category, symbols in API_SYMBOLS.items():
        for name, text in sources.items():
            for sym in symbols:
                if sym in text:
                    found.setdefault(category, f"`{sym}` ({name})")
    return found


def check(
    manifest_bytes: bytes | None, pbx: str, sources: dict[str, str]
) -> list[str]:
    problems: list[str] = []

    # ⚠️ VAKUM: taranacak kaynak yoksa ikinci yön HİÇBİR ŞEY ölçmemiş olur ve
    # sessizce yeşil kalır. Boş bir sayaç sıfır değildir.
    if not sources:
        problems.append(
            f"{RUNNER_SRC.name}/ altında taranacak kaynak dosya YOK — ikinci "
            "yön vakumda ölçüm yapamaz (boş bir sayaç sıfır değildir)"
        )

    if manifest_bytes is None:
        problems.append(
            "ios/Runner/PrivacyInfo.xcprivacy YOK — App Store zorunlu tutuyor, "
            "yokluğu RET sebebi"
        )
        return problems

    try:
        data = plistlib.loads(manifest_bytes)
    except Exception as e:  # noqa: BLE001 — sebep isimle raporlanır
        problems.append(
            f"manifest ayrıştırılamıyor ({e}) — bozuk plist paketlenemez"
        )
        return problems

    for k in REQUIRED_KEYS:
        if k not in data:
            problems.append(f"manifest `{k}` anahtarını TAŞIMIYOR")

    # ── YÖN 1: pakete giriyor mu? ────────────────────────────────────────
    # 🪤 Ham `count()` KULLANILMIYOR: tek bir satır dizgeyi İKİ kez taşır
    # (`PBXBuildFile` satırında hem ad hem `fileRef` yorumu geçer) ⇒ "6/4
    # bağlı" gibi anlamsız bir sayı çıkardı. Dört YAPISAL çapa ayrı aranıyor.
    lines = [l for l in pbx.splitlines() if "PrivacyInfo.xcprivacy" in l]
    anchors = {
        "PBXBuildFile girdisi": any(
            "isa = PBXBuildFile" in l and "fileRef" in l for l in lines
        ),
        "PBXFileReference girdisi": any("isa = PBXFileReference" in l for l in lines),
        "Runner grubu çocuğu": any(
            l.strip().endswith("*/,") and "isa =" not in l
            and "in Resources" not in l for l in lines
        ),
        "Resources build fazı": any("in Resources */," in l for l in lines),
    }
    missing = [name for name, ok in anchors.items() if not ok]
    if missing:
        problems.append(
            "manifest Xcode projesine TAM bağlı değil — eksik çapa(lar): "
            + ", ".join(missing)
            + ". Dosya depoda durur ama PAKETE GİRMEZ, ve mağaza yine reddeder"
        )

    # ── YÖN 2: beyan ↔ kaynak ────────────────────────────────────────────
    declared = {
        str(e.get("NSPrivacyAccessedAPIType"))
        for e in (data.get("NSPrivacyAccessedAPITypes") or [])
        if isinstance(e, dict)
    }
    in_source = scan_sources(sources)
    undeclared = sorted(set(in_source) - declared)
    for category in undeclared:
        problems.append(
            f"kaynak {in_source[category]} çağırıyor ama manifest "
            f"`{category}` BEYAN ETMİYOR — eksik beyan mağaza tarafında ret, "
            "ve boş bir dizi bunu sessizce taşır"
        )

    # Fazla-beyan: adıyla yazılır, BLOKLAMAZ (sebep dosya başlığında).
    for category in sorted(declared - set(in_source)):
        print(
            f"   📌 `{category}` beyan edildi, Runner kaynağında izi YOK — "
            "Dart tarafı bu tarayıcıya görünmez, o yüzden bloklamıyor"
        )

    return problems


def _read_sources() -> dict[str, str]:
    if not RUNNER_SRC.is_dir():
        return {}
    return {
        p.name: p.read_text(encoding="utf-8", errors="replace")
        for p in sorted(RUNNER_SRC.iterdir())
        if p.is_file() and p.suffix in SRC_SUFFIXES
    }


def _self_test() -> None:
    """Kapının yakaladığını iddia ettiği kusurları GERÇEKTEN yakaladığı."""
    good = plistlib.dumps(
        {k: [] if k != "NSPrivacyTracking" else False for k in REQUIRED_KEYS}
    )
    # GERÇEK pbxproj biçiminin dört çapası — bu depodan alındı, uydurulmadı.
    # Sahte bir dizi kullansaydık kapı, gerçeğin reddedeceği bir girdiyi kabul
    # ederdi (*test double gerçeğin kuralını uygulamaz*).
    wired = (
        "\t\tC0DE1A0200000000000AB102 /* PrivacyInfo.xcprivacy in Resources */ "
        "= {isa = PBXBuildFile; fileRef = C0DE1A0100000000000AB101 "
        "/* PrivacyInfo.xcprivacy */; };\n"
        "\t\tC0DE1A0100000000000AB101 /* PrivacyInfo.xcprivacy */ = "
        "{isa = PBXFileReference; lastKnownFileType = text.plist.xml; "
        'path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };\n'
        "\t\t\t\tC0DE1A0100000000000AB101 /* PrivacyInfo.xcprivacy */,\n"
        "\t\t\t\tC0DE1A0200000000000AB102 /* PrivacyInfo.xcprivacy in Resources */,\n"
    )
    clean = {"AppDelegate.swift": "import Flutter\nimport UIKit\n"}

    # ① POZİTİF KONTROL — sağlam hâl yeşil (kapı kırmızıya sıkışmış değil)
    assert not check(good, wired, clean), "ÖZ-TEST: sağlam hâl kırmızı yandı"

    # ② manifest yok
    assert check(None, wired, clean), "ÖZ-TEST: eksik manifest yakalanmadı"

    # ③ ⭐ dosya VAR ama projeye BAĞLI DEĞİL — kapının asıl sebebi
    assert check(good, "hiç atıf yok", clean), (
        "ÖZ-TEST: bağlanmamış manifest GEÇTİ — kapının bütün sebebi buydu"
    )

    # ④ bozuk plist
    assert check(b"<plist bozuk", wired, clean), "ÖZ-TEST: bozuk plist geçti"

    # ⑤ eksik anahtar
    partial = plistlib.dumps({"NSPrivacyTracking": False})
    assert check(partial, wired, partial and clean), (
        "ÖZ-TEST: eksik anahtar yakalanmadı"
    )

    # ⑥ ⭐ İKİNCİ YÖN — kaynak çağırıyor, manifest boş
    dirty = {
        "AppDelegate.swift": "let seen = UserDefaults.standard.bool(forKey: \"x\")"
    }
    assert check(good, wired, dirty), (
        "ÖZ-TEST: beyansız gerekçeli-API yakalanmadı — boş dizi sessizce taşıdı"
    )

    # ⑦ ⭐ İKİNCİ YÖNÜN POZİTİF İKİZİ — aynı kaynak, ama BEYAN EDİLMİŞ ⇒ yeşil.
    # Bu olmasaydı kapı "her UserDefaults kırmızıdır" derdi ve bir DENETİM
    # değil bir YASAK olurdu.
    declared_ok = plistlib.dumps(
        {
            "NSPrivacyTracking": False,
            "NSPrivacyTrackingDomains": [],
            "NSPrivacyCollectedDataTypes": [],
            "NSPrivacyAccessedAPITypes": [
                {
                    "NSPrivacyAccessedAPIType": (
                        "NSPrivacyAccessedAPICategoryUserDefaults"
                    ),
                    "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
                }
            ],
        }
    )
    assert not check(declared_ok, wired, dirty), (
        "ÖZ-TEST: beyan edilmiş API kırmızı yandı — kapı denetim değil yasak"
    )

    # ⑧ ⭐ VAKUM — taranacak kaynak yok
    assert check(good, wired, {}), "ÖZ-TEST: vakum yakalanmadı"

    print("  öz-test: 8/8 ✅")


def main() -> int:
    _self_test()
    if not PBXPROJ.exists():
        print(f"⛔ {PBXPROJ.relative_to(REPO)} yok")
        return 1
    sources = _read_sources()
    blob = MANIFEST.read_bytes() if MANIFEST.exists() else None
    problems = check(blob, PBXPROJ.read_text(encoding="utf-8"), sources)
    if problems:
        print("⛔ GİZLİLİK MANİFESTİ KAPISI — kırmızı:")
        for p in problems:
            print(f"   · {p}")
        return 1
    print(
        f"✅ gizlilik manifesti: var, geçerli, Xcode projesine 4/4 bağlı, ve "
        f"beyan {len(sources)} Runner kaynağıyla uyuşuyor"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
