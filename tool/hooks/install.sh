#!/bin/bash
# Taze bir klonda commit kapısını devreye sokar (C-206).
#
# Git `core.hooksPath`'i `.git/config`'e yazar — bu dosya asla izlenmez,
# yani bu adım OTOMATİK değildir ve olamaz (npm'in postinstall'ı gibi bir
# "klonlanınca kendi kendine çalışır" kancası düz git+Flutter deposunda yok).
# Dürüst çözüm: TEK komutluk, isimli bir kurulum adımı — README'de yazılı,
# icat edilmiş bir otomasyon YOK.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x tool/hooks/pre-commit
git config core.hooksPath tool/hooks
echo "core.hooksPath = tool/hooks — commit kapısı bu klonda etkin."
