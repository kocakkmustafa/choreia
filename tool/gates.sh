#!/bin/bash
# Üç koşucunun HEPSİ, ve çıkış kodları GERÇEKTEN kontrol edilerek.
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
run() {
  local name="$1"; shift
  printf '── %s\n' "$name"
  if "$@" > /tmp/choreia-gate.$$ 2>&1; then
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

if [ "$fail" -ne 0 ]; then
  echo
  echo "⛔ KAPI KIRMIZI — commit etme."
  exit 1
fi
echo
echo "✅ hepsi yeşil"
