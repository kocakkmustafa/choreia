#!/bin/bash
# Koşucuların HEPSİ, ve çıkış kodları GERÇEKTEN kontrol edilerek.
#
# NİYE VAR (C-205): bu depoda commit öncesi kapı YOKTU. Kullandığım kalıp
#
#     flutter test 2>&1 | tail -1
#     git add … ; git commit …
#
# iki AYRI satırdı — `&&` bile yok. Yani commit, test sonucundan tamamen
# bağımsız koşuyordu ve tek koruma benim çıktıyı okumamdı. 2026-08-07'de
# `d1335ce` kırmızı süitle push edildi; o an "okumadım" diye sınıfladım.
# Yarım doğruydu: DÜŞECEK BİR KAPI HİÇ YOKTU.
#
# Boru hattı tuzağı ayrıca gerçek ve ölçüldü: `false | tail -1` çıkış kodu
# 0 döner — `tail` başarılı olur ve başarısızlığı yutar. `&&` ile zincirlemek
# de kurtarmaz. Bu betikte boru hattı yok; her koşucu doğrudan çalışır ve
# `$?` okunur.
#
# Kullanım:  tool/gates.sh && git commit …
set -u
cd "$(dirname "$0")/.."

fail=0
skipped=0
run() {
  local name="$1"; shift
  printf '── %s\n' "$name"
  "$@" > /tmp/choreia-gate.$$ 2>&1
  local code=$?
  if [ "$code" -eq 0 ]; then
    tail -1 /tmp/choreia-gate.$$
  elif [ "$code" -eq 2 ]; then
    # ÜÇÜNCÜ HÂL (koordinatör hükmü, C-210): "ortam yok" ne yeşil ne
    # kırmızı. Yerel eksiklik (harvest havuzu boş, motion-core kardeş repo
    # checkout edilmemiş) repo-geneli commit'i BLOKLAMAZ — ama "hepsi
    # yeşil"e SESSİZCE karışmaz da; ayrı sayılır, ayrı görünür. Kod bunu
    # exit 2 ile işaretler; koşucu adına ve içeriğine BAKMAZ, yalnız çıkış
    # koduna — isim etiket kalıp davranışı belirlemesin diye.
    skipped=$((skipped+1))
    echo "   ⚪ ORTAM YOK"
    tail -1 /tmp/choreia-gate.$$
  else
    fail=1
    echo "   🔴 KIRMIZI"
    tail -25 /tmp/choreia-gate.$$
  fi
  rm -f /tmp/choreia-gate.$$
}

# The pure-Dart engine has its own package_config. Root `flutter pub get`
# does not resolve the engine's `test` dependency in a fresh CI checkout.
run "engine dependencies" bash -c 'cd packages/choreia_engine && dart pub get'
run "flutter test"        flutter test
run "flutter analyze"     flutter analyze
run "Salsa asset manifest" dart run tool/build_salsa_integrity_manifest.dart --check
run "v2l app source projection" python3 tool/check_v2l_source_projection.py --check
run "v2l source negative controls" python3 tool/test_v2l_source_projection.py
run "engine (dart test)"  bash -c 'cd packages/choreia_engine && dart test'
run "validate_content"    python3 tools/validate_content.py
run "metric vocabulary"   python3 tools/validate_metric_vocabulary.py
run "model provenance"    bash -c 'cd tools && python3 test_model_provenance.py'
run "coordinate space"    bash -c 'cd tools && python3 test_coordinate_space.py'
run "network dependency"  python3 tools/network_dependency_check.py

# Sır sızıntısı taraması (CHO-P0-002). Aile emsali YOK — dört kardeş hattın
# hiçbirinde gerçek bir secret-scan adımı yok (ölçüldü); bu kapı sıfırdan
# yazıldı. `git ls-files` üzerinden çalışır: yalnız İZLENEN (commit'e girecek)
# dosyaları tarar, `.gitignore`ın zaten dışladığı sınıfları (key.properties,
# *.jks, *.ttf) ikinci kez taramaz — iki ayrı savunma katmanı.
run "secret scan"         python3 tools/secret_scan.py

# Gizlilik manifesti (C-266, A8). Kapı kısıtına uygun: A tablosunun KENDİ
# kalemini doğruluyor. İki yön: ① manifest Xcode projesine 4/4 bağlı mı
# (bağlı değilse depoda durur, PAKETE GİRMEZ) ② boş `NSPrivacyAccessedAPITypes`
# beyanı Runner kaynağıyla hâlâ uyuşuyor mu (boşluk da bir iddiadır).
run "privacy manifest"    python3 tools/privacy_manifest_check.py

# Şablon varlık denetimi (H-56/C-296, D8). İlk yazılışta BAĞLANMAMIŞTI —
# "Ostinato'nunki de bağlı değil" varsayımı ölçülmeden yapılmıştı ve
# yanlıştı (Ostinato'nunki `tools/run_gates.sh`e bağlı). BAĞLANMAMIŞ kapı
# koşmayan kapıdır. H-50'nin mutabakat-kaydı deseniyle bağlandı: bilinen
# 25 stok varlık için kırmızı YANMAZ (adlı+tarihli kayıt, dosyanın
# kendisinde), ama kayıtta OLMAYAN yeni bir stok varlık yine öter.
run "template assets"    python3 tools/validate_template_assets.py

# Kimlik okuması (C-233, koordinatör hükmü). Kapı YALNIZ ÇÜRÜTMEDE öter;
# kanıt-yok BLOKLAMAZ ve `docs/design/IDENTITY-REGISTER.md` kütüğünde sayılır.
# Transkript havuzu yoksa exit 2 (⚪ ORTAM YOK) — C-210'un üçüncü hâli.
run "identity read"       python3 tools/identity_read.py

# Kapanış otoritesi (C-249). Bir yer "C-NNN kapandı" diyorsa, C-NNN'in KENDİ
# durum sütunu da öyle demeli. Otorite A; B işaretçi, C hiç değil.
# Defter 2026-08-15'ten beri depo İÇİNDE (`app/workspace/`) → taze klonda GELİR.
# exit 2 (⚪ ORTAM YOK) artık nadir olmalı; olursa gerçek kayıp belirtisidir.
run "closure authority"   python3 tools/closure_authority.py

# Defter tazeliği (C-267, A6). Kapı kısıtına uygun: A tablosunun KENDİ kalemini
# doğruluyor — ve `closure_authority`den BAŞKA bir şey ölçüyor: o kapanış
# otoritesine bakar, defter bir hafta bayat olsa da yeşil kalır. Bu kapı
# SINIRA bakar: ① commit indi/kaydı yok ② kayıt yazıldı/işi inmedi.
# Defter depo içinde (bkz. yukarı) → taze klonda GELİR.
run "ledger freshness"    python3 tools/ledger_freshness_check.py

# Hasat aracı öz-testleri (C-207, koordinatör sevki, A1 bulgusu).
#
# Bu 7 aracın kendi `--self-test`i vardı ve HİÇBİRİ buraya bağlı değildi —
# "7/7 yeşil" hasat hattı kodunu hiç KAPSAMIYORDU. Tam da enter.metric
# dispatch'inin yaşadığı bölge. Kendi kapsamı olmayan bir kapı, o bölgede
# olan biteni ölçmez; adı buraya eklenmek KAPSAMIN kendisi.
run "prepare_take self-test"        python3 tools/prepare_take.py --self-test
run "probe_knee_dips self-test"     python3 tools/probe_knee_dips.py --self-test
run "movement_isolator self-test"   python3 tools/movement_isolator.py --self-test
run "camera_angle_gate self-test"   python3 tools/camera_angle_gate.py --self-test
run "build_reference self-test"     python3 tools/build_reference.py --self-test
run "beat_annotate self-test"       python3 tools/beat_annotate.py --self-test
run "identity_read self-test"     python3 tools/identity_read.py --self-test
run "closure_authority self-test" python3 tools/closure_authority.py --self-test
run "ledger_freshness self-test"  python3 tools/ledger_freshness_check.py --self-test
run "artifact_keyset_gate self-test" python3 tools/artifact_keyset_gate.py --self-test
run "secret_scan self-test"       python3 tools/secret_scan.py --self-test
# C-276. Diğer öz-testlerden farklı bir şey ölçüyor: ötekiler bir ARACIN
# doğruluğunu kanıtlıyor, bu bir KONTROLÜN BAĞLI OLDUĞUNU. Sebebi ölçülmüş —
# `validate_content.py`nin yüzey-dili kontrolü aynı gece iki kez sessizce
# devre dışı kaldı (önce fonksiyon, sonra çağrı) ve script her seferinde
# exit 0 verdi. Çağrılmayan bir kontrol, geçen bir kontrolden ayırt edilemez.
run "validate_content self-test" python3 tools/validate_content.py --self-test
run "template_assets self-test" python3 tools/validate_template_assets.py --selftest

if [ "$fail" -ne 0 ]; then
  echo
  echo "⛔ KAPI KIRMIZI — commit etme."
  exit 1
fi
echo
if [ "$skipped" -ne 0 ]; then
  echo "✅ hepsi yeşil ($skipped ortam-yok ADIYLA atlandı — yukarıda ⚪)"
else
  echo "✅ hepsi yeşil"
fi
