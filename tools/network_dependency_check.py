#!/usr/bin/env python3
r""""CİHAZDA KALIR / YÜKLENMEZ" İDDİA KAPISI — Ostinato O-080 aktarımı (A3, C-211).

2026-09-24: Bu iddia kamera karesi/landmark ve seans geçmişi içindir;
Motion hesabının e-posta, görünen ad ve kimlik ağı ayrıca açıktır ve
`NETWORK_DEPS_RECORDED` ile privacy manifestinde beyan edilir.

    Doğru bir iddianın korunmaması, gelecekteki bir yalandır.

Ölçüm (A3): `lib/app/onboarding/first_run_view.dart` "Video never leaves
your phone ... nothing is recorded or uploaded" diyor (kamera izin metniyle
`content_claims_test`'le ÇİVİLİ). `pubspec.yaml` `google_fonts` taşıyor. Bu
iddiayı koruyan HİÇBİR kapı yoktu (A3, ilk ölçüm).

## Üç kanal (koordinatörün reçetesi, ①②③)

① **kod izi** — sevk edilen `lib/` kaynağı bir yükleyici çağrısı (`http.post`,
   `Dio(`, `WebSocket`, `.upload(`…) taşıyor mu? İddia da varsa bu bir
   ÇELİŞKİ — kapı öter.
② **bağımlılık kaydı** — ağa-çıkabilen HER bağımlılık `NETWORK_DEPS_RECORDED`da
   adıyla VE gerekçesiyle. Kayıt bir MUAFİYET DEĞİL, bir KARAR NOKTASIdır —
   "ağa çıkan = kötü" YANLIŞ kural olurdu (O-057); `google_fonts` bir GET
   yapar, kullanıcı verisi taşımaz, iddiayı YALANLAMAZ.
③ **vakum koruması** — iddia HİÇBİR yüzeyde bulunamıyorsa bu da KIRMIZI: ya
   bilerek kaldırıldı (kapı da emekli edilmeli) ya tarama kırık. Sessiz
   "geçti" hiçbir zaman doğru değildir.

## Ostinato/Lissom'dan AYNEN alınan vs. Choreia için TÜRETİLEN

- `NETWORK_DEP_HINTS`, `UPLOADER_TRACES` — Lissom'un GENİŞLETİLMİŞ sürümünden
  AYNEN (paket-ailesi/API izleri, projeye özgü değil). Ostinato'nun
  ORİJİNALİ DEĞİL: o sürümde alternatiften hemen sonra `:` bekleniyordu, 6
  alternatif `\w*` taşımıyordu → `posthog_flutter:` gibi sonekli gerçek
  paket adları sessizce kaçıyordu (Lissom'un bulduğu delik).
- **İKİNCİ DELİK (Gravita buldu, koordinatör beş hatta doğruladı) BURADA
  KAPATILIYOR:** Ostinato'nun kapısı (ve Lissom'un fixli sürümü de) yalnız
  `pubspec.yaml`'ı tarıyordu. Ama `http` (+ `http_parser`) Choreia'nın
  `pubspec.lock`unda `google_fonts`un TRANSİTİF bağımlılığı olarak duruyor
  ve `pubspec.yaml`da HİÇ görünmüyor — yalnız yaml taransa bu iki paket
  hiç yakalanmaz, kapı vakum-doğru olurdu. Bu yüzden `pubspec.lock` da
  taranıyor; aynı `NETWORK_DEP_HINTS` regex'i, iki dosyaya karşı.
- `NETWORK_DEPS_RECORDED` — Ostinato'nunki KOPYALANMADI, Choreia'nın kendi
  `google_fonts` + `http`/`http_parser` gerekçesiyle SIFIRDAN yazıldı.
- `UPLOAD_CLAIM` — **kopyalanmadı, Choreia'nın GERÇEK sevk edilen metninden
  TÜRETİLDİ** ("Video never leaves your phone ... nothing is recorded or
  uploaded", "It runs on your phone"). Başka bir hattın regex'i körlemesine
  kopyalansaydı burada SIFIR eşleşme verir, kapı VAKUM-DOĞRU olurdu (③'ün
  tam yakalaması gereken hâl — ve bu üç hattın ortak dersi: bir kapının
  kapsamı, yazarının görebildiği yerel gerçekliğin sınırında çizilir).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# ── ② bağımlılık kaydı ──────────────────────────────────────────────────
NETWORK_DEPS_RECORDED = {
    "google_fonts": "yazı tipi indirir (GET); kullanıcı verisi TAŞIMAZ — "
                     "gizlilik iddialarını yalanlamaz. CHO-P0-002 (2026-08-19): "
                     "runtime GET artık KAPALI (`main.dart` "
                     "`GoogleFonts.config.allowRuntimeFetching = false`) — üç "
                     "aile `assets/fonts/`da self-host (`tool/fetch_fonts.sh`). "
                     "Paket bağımlılığı hâlâ burada (kayıt hâlâ doğru), ama "
                     "artık çalışma zamanında hiç ağa çıkmıyor.",
    "http": "google_fonts'un TRANSİTİF bağımlılığı (pubspec.lock, "
            "pubspec.yaml'da doğrudan YOK) — Choreia kodu bunu doğrudan "
            "IMPORT ETMİYOR (①'in kod-izi taraması ayrıca doğrular); "
            "google_fonts'un kendi GET'i için kullanılıyor",
    "http_parser": "http paketinin AYRIŞTIRMA yardımcı kütüphanesi — ağa "
                   "kendisi ÇIKMAZ, yalnız http'nin zaten aldığı yanıtı "
                   "ayrıştırır",
    "supabase": "Motion hesabının Auth ve uygulamaya özel üyelik için ortak "
                "sunucuyla konuşan istemcisi; e-posta, görünen ad ve hesap "
                "kimliği gizlilik manifestinde beyan edildi.",
    "supabase_common": "Supabase istemcisinin ortak alt katmanı; Motion hesabı "
                       "ağına aittir, kamera karesi veya seans kaydı taşımaz.",
    "supabase_flutter": "Motion hesabının Flutter oturum/deep-link köprüsü; "
                        "hesap verileri gizlilik manifestinde beyan edildi.",
    "web_socket": "Supabase transitif ağ taşıyıcısı; doğrudan uygulama "
                  "kullanımı yok, Motion hesap akışına bağlıdır.",
    "web_socket_channel": "Supabase transitif soket kanalı; doğrudan "
                          "uygulama kullanımı yok, hesap ağına bağlıdır.",
}

#: Lissom'un genişletilmiş sürümünden AYNEN — Ostinato'nun orijinali
#: (alternatiften hemen sonra `:`, `\w*` yok) 6 sonekli gerçek paket adını
#: (`posthog_flutter` sınıfı) kaçırıyordu.
NETWORK_DEP_HINTS = re.compile(
    r"^\s+(http\w*|dio\w*|firebase\w*|sentry\w*|posthog\w*|amplitude\w*|"
    r"mixpanel\w*|segment\w*|appsflyer\w*|adjust\w*|google_fonts|"
    r"supabase\w*|graphql\w*|web_socket\w*):",
    re.MULTILINE)

# ── ① kod izi ────────────────────────────────────────────────────────────
#: Kullanıcı verisini DIŞARI taşıyan kod yolları. Dart/Flutter'ın kendi ağ
#: API'leri, projeye özgü değil — AYNEN.
UPLOADER_TRACES = re.compile(
    r"\bhttp\.post\b|\bhttp\.put\b|\bDio\(|\bHttpClient\(|\bWebSocket\b|"
    r"MultipartRequest|\.upload\(")

# ── ③ vakum koruması ─────────────────────────────────────────────────────
#: Choreia'nın GERÇEK sevk edilen cümlelerinden TÜRETİLDİ (grep, kopya
#: değil): `lib/app/onboarding/first_run_view.dart` — "Video never leaves
#: your phone ... nothing is recorded or uploaded" + "It runs on your phone".
UPLOAD_CLAIM = re.compile(
    r"never\s+leaves\s+your\s+(?:phone|device)|"
    r"nothing\s+is\s+recorded\s+or\s+uploaded|"
    r"runs?\s+on\s+your\s+(?:phone|device)",
    re.IGNORECASE)


def _dep_problems(text: str, source_name: str) -> list[str]:
    problems: list[str] = []
    for m in NETWORK_DEP_HINTS.finditer(text):
        dep = m.group(1)
        if dep not in NETWORK_DEPS_RECORDED:
            problems.append(
                f"kayıtsız ağ-bağımlılığı: `{dep}` — {source_name}'de "
                f"bulundu ama `NETWORK_DEPS_RECORDED`a GEREKÇESİYLE "
                f"yazılmamış. Bu bir hata DEĞİL — bir KARAR NOKTASI: "
                f"bağımlılık kullanıcı verisi taşıyabilir mi? "
                f"Taşımıyorsa gerekçeyle kaydet, taşıyorsa gizlilik "
                f"iddialarını gözden geçir."
            )
    return problems


def _pubspec_problems() -> list[str]:
    """İKİ dosya taranır (C-211, ikinci delik): `pubspec.yaml` DOĞRUDAN
    bağımlılıkları taşır, `pubspec.lock` TRANSİTİF olanları da — yalnız
    yaml taramak Choreia'nın kendi `http`/`http_parser`'ını (google_fonts
    üzerinden gelen, yaml'da hiç görünmeyen) sessizce kaçırırdı."""
    problems: list[str] = []
    problems += _dep_problems((ROOT / "pubspec.yaml").read_text(),
                              "pubspec.yaml")
    problems += _dep_problems((ROOT / "pubspec.lock").read_text(),
                              "pubspec.lock (transitif)")
    return problems


def _sites(lib_root: Path, pattern: re.Pattern) -> list[tuple[Path, int, str]]:
    sites: list[tuple[Path, int, str]] = []
    for f in sorted(lib_root.rglob("*.dart")):
        text = f.read_text(encoding="utf-8")
        for i, line in enumerate(text.splitlines(), start=1):
            if pattern.search(line):
                sites.append((f, i, line.strip()))
    return sites


def main() -> int:
    lib_root = ROOT / "lib"
    problems: list[str] = _pubspec_problems()

    # ① kod izi — iddia VARKEN yükleyici izi de varsa çelişki
    claims = _sites(lib_root, UPLOAD_CLAIM)
    uploaders = _sites(lib_root, UPLOADER_TRACES)
    if claims and uploaders:
        problems.append(
            f"ÇELİŞKİ: {len(claims)} yüzey cihazda-kalır iddiası taşıyor "
            f"AMA kaynakta {len(uploaders)} yükleyici izi bulundu: " +
            "; ".join(f"{f.relative_to(ROOT)}:{i}" for f, i, _ in uploaders[:3])
        )

    # ③ vakum koruması — iddia HİÇ bulunamıyorsa bu da kırmızı
    if not claims:
        problems.append(
            "VAKUM: `UPLOAD_CLAIM` `lib/`de SIFIR eşleşme buldu. Ya iddia "
            "bilerek kaldırıldı (bu kapı da emekli edilmeli) ya tarama "
            "kırık (regex Choreia'nın güncel cümlesini kaçırıyor "
            "olabilir). Sessiz 'geçti' burada YANLIŞ olurdu."
        )

    # Öz-testler — kapı KIRMIZI yanabiliyor (sabotaj), her biri ayrı ayrı.
    # İKİ VAKA BİLEREK EKLENDİ (koordinatörün dersi): Ostinato'nun kendi
    # öz-testi SONEKLİ bir paket ve TRANSİTİF-yalnız bir bağımlılık
    # içermiyordu, çünkü onun yerel gerçekliğinde ikisi de yoktu — bir
    # kapının öz-testi, yazarının görmediği vakayı sınayamaz. Choreia'nın
    # gerçekliğinde `http` TAM OLARAK transitif-yalnız vaka, ama bu öz-test
    # onu SENTETİK olarak da sınıyor, kendi gerçekliğine bağlı kalmadan.
    fake_suffix_yaml = "dependencies:\n  posthog_flutter: ^1.0.0\n"
    if not _dep_problems(fake_suffix_yaml, "test"):
        print("❌ ÖZ-TEST BAŞARISIZ (② sonek vakası): kayıtsız "
             "`posthog_flutter` (SONEKLİ paket adı) kapıyı ötürmedi — "
             "Lissom'un bulduğu delik burada yeniden açılmış olabilir")
        return 2
    fake_transitive_lock = "packages:\n  amplitude_flutter:\n    dependency: transitive\n"
    if not _dep_problems(fake_transitive_lock, "test"):
        print("❌ ÖZ-TEST BAŞARISIZ (② transitif-lock vakası): yalnız "
             "lock'ta görünen sonekli bir paket kapıyı ötürmedi")
        return 2
    if not UPLOADER_TRACES.search("await Dio().post(url, data: payload);"):
        print("❌ ÖZ-TEST BAŞARISIZ (①): bilinen bir yükleyici izi "
             "(`Dio(`) yakalanmadı")
        return 2
    if UPLOAD_CLAIM.search("This screen shows your dance progress."):
        print("❌ ÖZ-TEST BAŞARISIZ (③ ikizi — YANLIŞ-POZİTİF): iddia "
             "taşımayan sıradan bir cümle yanlışlıkla eşleşti")
        return 2
    if not UPLOAD_CLAIM.search("Video never leaves your phone."):
        print("❌ ÖZ-TEST BAŞARISIZ (③): bilinen bir iddia cümlesi "
             "TÜRETİLEN regex'le eşleşmedi")
        return 2

    print(f"Cihazda-kalır iddiası — {len(claims)} yüzey, {len(uploaders)} "
          f"yükleyici izi, {len(NETWORK_DEPS_RECORDED)} kayıtlı bağımlılık "
          f"(yaml+lock taranmış), 5 öz-test geçti.")
    if problems:
        print(f"\n❌ {len(problems)} sorun:")
        for p in problems:
            print(f"  {p}")
        return 1
    print("✅ İddia korunuyor: yükleyici izi yok, bağımlılıklar (yaml+lock) "
          "kayıtlı, vakum değil.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
