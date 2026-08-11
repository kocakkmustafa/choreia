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

run "flutter test"        flutter test
run "flutter analyze"     flutter analyze
run "engine (dart test)"  bash -c 'cd packages/choreia_engine && dart test'
run "validate_content"    python3 tools/validate_content.py
run "metric vocabulary"   python3 tools/validate_metric_vocabulary.py
run "model provenance"    bash -c 'cd tools && python3 test_model_provenance.py'
run "coordinate space"    bash -c 'cd tools && python3 test_coordinate_space.py'

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
run "artifact_keyset_gate self-test" python3 tools/artifact_keyset_gate.py --self-test

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
