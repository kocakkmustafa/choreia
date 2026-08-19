#!/bin/bash
# Instrument Serif + Manrope + IBM Plex Mono yazı tiplerini indirir ve
# SHA-256'sını DOĞRULAR (CHO-P0-002 — lissom L-348/LIS-P0-002 ile AYNI
# desen: pinli URL + hash-doğrulama build kapısı, ikili git'e commit edilmez;
# `tool/fetch_pose_model.sh`nin de kardeşi).
#
# NİYE BU HASH'LER: elle seçilmedi. `google_fonts` paketinin bu projenin
# `pubspec.lock`ta ÇÖZÜLMÜŞ sürümü (6.3.3) kendi
# `lib/src/google_fonts_parts/part_{i,m}.g.dart` dosyalarında HER ağırlık
# için bu SHA-256'yı taşıyor; `GoogleFontsFile.url` getter'ı
# `https://fonts.gstatic.com/s/a/$hash.ttf` üretiyor. Bu betik runtime'da
# `google_fonts`un ZATEN indireceği TAM O DOSYAYI, TAM O URL'DEN, build-
# time'a taşıyor — yeni bir kaynak İCAT EDİLMEDİ.
#
# NEDEN 4 DOSYA, TÜM AĞIRLIKLAR DEĞİL: `lib/app/theme.dart` `ChoreiaType`
# yalnız Instrument Serif'i varsayılan (tek statik ağırlık, ailenin
# KENDİSİNDE başka ağırlık YOK — `part_i.g.dart`da tek `GoogleFontsVariant`
# w400/normal) `display()`de, Manrope'u w400 (`body()` varsayılanı VE
# `manropeTextTheme` — ÖLÇÜLDÜ: Flutter'ın Material3 varsayılan
# `TextTheme`inde HER rol fontWeight'i `null` = tema varsayılanı w400,
# `test/_font_weight_probe_test.dart` ile bu turda doğrulandı, tahmin
# değil) ve w600'de (`body(weight: FontWeight.w600)` — grep'lenmiş tek
# override) ve IBM Plex Mono'yu yalnız w500'de (`label()`, hardcoded, tek
# çağrı yeri) kullanıyor. Kullanılmayan ağırlığı bundle etmek paket
# boyutunu büyütür, hiçbir ekranı değiştirmez.
set -euo pipefail

DEST_DIR="assets/fonts"
declare -a FONTS=(
  # dest_filename                    sha256                                                            size
  "InstrumentSerif-Regular.ttf       309aadf6d6254529fbfb5451b0905820ca2f4b9eccbb58fefcc161ae51020c72  48340"
  "Manrope-Regular.ttf               1ddeeeff9fe3d294f709f2239557278930f56dab89db1fe535dc5c35cd67e0ee  94948"
  "Manrope-SemiBold.ttf              8791ca409cf36b8b2842e40b6b1cd5b42cca064b4fdf24e30f5611536793429d  95072"
  "IBMPlexMono-Medium.ttf            ccde6e24d2f07f518ab9860bb438d768dade104dd9f4a5e8c7442885ff4bad81  76544"
)

cd "$(dirname "$0")/.."
mkdir -p "$DEST_DIR"

verify() {
  local got
  got=$(shasum -a 256 "$1" | awk '{print $1}')
  [ "$got" = "$2" ] || { echo "⛔ SHA UYUŞMUYOR: $1"; echo "   beklenen: $2"; echo "   bulunan : $got"; return 1; }
}

for entry in "${FONTS[@]}"; do
  read -r name hash size <<< "$entry"
  dest="$DEST_DIR/$name"
  url="https://fonts.gstatic.com/s/a/${hash}.ttf"
  if [ -f "$dest" ] && verify "$dest" "$hash" 2>/dev/null; then
    echo "✓ zaten yerinde ve doğrulandı: $dest"
    continue
  fi
  echo "indiriliyor: $name ← $url"
  curl -fsSL "$url" -o "$dest"
  verify "$dest" "$hash"
  got_size=$(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest")
  [ "$got_size" = "$size" ] || { echo "⛔ BOYUT UYUŞMUYOR: $dest ($got_size ≠ $size)"; exit 1; }
  echo "✓ doğrulandı: $dest ($size bayt)"
done

echo "→ $DEST_DIR (4/4 doğrulandı)"
