# YULAlab — yerel Codex girişi

Önce [ortak bağlam girişini](../../../AGENTS.md), ardından [bu reponun tek yerel ürün/güvenlik kaynağını](CLAUDE.md) oku. CLAUDE.md içindeki yerel bilgiler Codex ve Claude için aynıdır; teknik yöntemi model seçer, dosya işlem yetkisi üretmez.

## Yığın
- Flutter (stable) / Dart ^3.6 · durum yönetimi: yok (Riverpod/bloc yok); `ChangeNotifier`/`ValueNotifier`.
- Kurulum: `flutter pub get` · Analiz: `flutter analyze` · Test: `flutter test` (CI `tool/gates.sh` ile aynı kapıları koşar).
- Motor ayrı pakettir: `packages/choreia_engine` (`cd packages/choreia_engine && dart test`). İçerik doğrulama: `python3 tools/validate_content.py`.

## Kurallar
- **Minimal diff:** yalnız istenen dosyalara dokun; biçimlendirme/yeniden adlandırma turu yapma.
- Yerelleştirme: ARB/`gen-l10n` yok. Metinler `content/l10n/{catalog,course}.<dil>.json` (14 dil) ve `lib/app/localization/` Dart haritalarındadır; anahtarlar kaynak metne bağlıdır.
- Yerelleştirme kapıları (kök dizinden): `python3 -B tool/l10n/validate_catalogs.py` ve `python3 -B tool/l10n/generate_bases.py`; ayrıntı `tool/l10n/README.md`.
- Testler: `test/*_test.dart` (düz klasör), motor testleri `packages/choreia_engine/test`; yeni davranışa test ekle; mevcut testi silme ya da atlatma.
- Bitirmeden: `bash tool/gates.sh` temiz olmalı (analiz + test + içerik kapıları); çıktının son 5 satırını rapora koy.

## Dokunulmaz
- Sır dosyaları (`.env*`, anahtarlar, `~/.secrets`), imzalama yapılandırması, fiyat/abonelik kimlikleri, `supabase/` — yalnız açık talimatla.
- Mağaza meta verisi (`docs/store/`) ve sürüm numarası — yalnız açık talimatla.
- Motion Core pini (`pubspec.yaml` git `ref`) — yalnız açık talimatla; Core değişikliği ayrı PR ve kurucu onayı ister.
- Kamera özelliği kapalı kalır: Core'un kamera bayrağı (`motionCameraCoachingAvailable`, `lib/main.dart`) açılmaz.
- Burun Farkı ve Iron Bank'a dokunulmaz.
