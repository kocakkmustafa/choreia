#!/usr/bin/env python3
"""Referans artefaktlarında SESSİZ ALAN KAYBI kapısı.

Neden bu araç var
-----------------
Choreia'da aynı arıza ÜÇ KEZ tekrarlandı (C-091, C-113 Bölüm 2, C-113 Bölüm 4):
bir yeniden üretim, artefaktta duran bir alanı yok etti ve kimse fark etmedi.
Üçünün ortak noktası elle-yamamak DEĞİL — üçüncüsü (`excludedNotLesson`) düpedüz
TÜRETİLEN bir alandı, girdisi (kaynağın kendisi) havuzdan çıkınca kayboldu.

Ortak nokta şu: **kaybı gören tek yer diff'tir, ve diff yeniden üretilen JSON'da
okunmaz.** Üç referansın satır-diff'i binlerce ondalık sayı değişikliği üretiyor;
içindeki `- "excludedNotLesson": [` satırı gözden kaçar. Bu yüzden bu kapı
satırları değil ANAHTAR YOLLARINI karşılaştırır: sayısal churn tamamen görünmez
olur, kaybolan bir alan ise tek satırlık hata olarak çıkar.

Ölçünün sınırı (dürüstlük notu)
-------------------------------
Bu kapı bir alanın VARLIĞINI ölçer, DOĞRULUĞUNU ölçmez. `spokenWords: 9` yerine
`spokenWords: 0` yazılsa bu araç susar. Alan-düzeyi kayıp bu hattın ölçülmüş
arıza kipiydi (3 vaka); değer-bozulmasının ölçülmüş bir vakası YOK, o yüzden
buraya bir kapı konmadı — ihtiyaç ÖLÇÜLDÜĞÜNDE eklenir.

Kullanım
--------
    python3 tools/reference_keyset_gate.py            # HEAD'e karşı
    python3 tools/reference_keyset_gate.py --update   # taban çizgisini tazele
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REFS = Path(__file__).resolve().parents[1] / "content/references"
DECISIONS_NAME = "decisions.json"

# Bir alanın kaybı SORUN DEĞİLDİR, eğer yerine geçen adlandırılmışsa. Kasıtlı
# kaldırmalar buraya İSMİYLE ve GEREKÇESİYLE yazılır — sessizce geçmez.
DECLARED_REMOVALS: dict[str, str] = {
    "provisionalReason": ("M-F-166 ile değiştirildi: tek serbest-metin gerekçe "
                          "yerine bağımsız çözülebilir isimli temeller listesi "
                          "(statusBases). C-111'in kök nedeni tek-temellilikti."),
}


def keypaths(obj: object, prefix: str = "") -> set[str]:
    """Anahtar YOLLARI kümesi. Dizi indeksleri `[]` ile sıkıştırılır.

    Sıkıştırma kasıtlı: bir dizinin UZUNLUĞU her üretimde değişebilir (kaynak
    sayısı, çevrim sayısı), ama içindeki ALAN ADLARI değişmemeli. İndeksleri
    korumak kapıyı gürültüye boğar ve gürültülü kapı kapatılır.
    """
    found: set[str] = set()
    if isinstance(obj, dict):
        for key, value in obj.items():
            path = f"{prefix}.{key}" if prefix else key
            found.add(path)
            found |= keypaths(value, path)
    elif isinstance(obj, list):
        for item in obj:
            found |= keypaths(item, prefix + "[]")
    return found


def head_version(rel: str) -> object | None:
    """Dosyanın HEAD'deki hâli; yeni dosyada None."""
    result = subprocess.run(["git", "show", f"HEAD:{rel}"],
                            capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return None
    return json.loads(result.stdout)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    failures = 0
    checked = 0

    for path in sorted(REFS.glob("*.json")):
        rel = str(path.relative_to(repo_root))
        old = head_version(rel)
        if old is None:
            print(f"· {path.name:<28}YENİ dosya — taban çizgisi yok, atlandı")
            continue
        new = json.loads(path.read_text(encoding="utf-8"))
        checked += 1

        lost = keypaths(old) - keypaths(new)
        # Yolun herhangi bir parçası beyan edilmiş kaldırmaysa, o yol beklenen
        # kayıptır (alt-alanları da öyle: kök gidince yaprakları da gider).
        undeclared = sorted(
            p for p in lost
            if not any(seg in DECLARED_REMOVALS for seg in p.split("."))
        )
        gained = sorted(keypaths(new) - keypaths(old))

        if undeclared:
            failures += 1
            print(f"✗ {path.name:<28}{len(undeclared)} ALAN SESSİZCE KAYBOLDU")
            for p in undeclared:
                print(f"    ✗ {p}")
            print("    → ya alanı geri getir, ya DECLARED_REMOVALS'a "
                  "gerekçesiyle yaz. Sessiz kayıp seçenek değil.")
        else:
            note = f"  (+{len(gained)} yeni)" if gained else ""
            print(f"✓ {path.name:<28}alan kaybı yok{note}")
        for p in gained:
            print(f"    + {p}")

    print(f"\n{checked - failures}/{checked} artefakt alan bütünlüğünü koruyor.")
    print("\nNOT: bu kapı alanın VARLIĞINI ölçer, DEĞERİNİ ölçmez. Ölçülmüş "
          "arıza kipi alan kaybıydı (3 vaka); değer-bozulması ölçülmedi, o "
          "yüzden buraya kapı konmadı.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
