#!/usr/bin/env python3
r""""SIR SIZINTISI YOK" İDDİA KAPISI — CHO-P0-002.

Aile emsali yok: gravita/jablab/lissom/ostinato CI'larının hiçbirinde
gerçek bir SECRET-SCAN adımı taşınmıyor (bu turda ölçüldü, dördü de tarandı)
— roadmap'in "secret scan" maddesi Choreia'da İLK kez, sıfırdan yazılıyor.

## İki kanal

① **desen taraması** — İZLENEN her dosyanın İÇERİĞİ bilinen sır biçimlerine
   (AWS anahtarı, özel-anahtar bloğu, GitHub token, Google/Stripe API
   anahtarı, generic `password=`/`secret=`/`api_key=` atamaları) karşı
   taranır. `git ls-files` kullanılır — yalnız İZLENEN dosyalar, `.gitignore`
   zaten dışladıklarını (ör. `assets/models/*.task`, `assets/fonts/*.ttf`,
   `android/key.properties`) ikinci kez taramak gürültü üretirdi.
② **yasak-dosya kontrolü** — android_signing_test.dart'ın ZATEN yaptığı tek
   kalemi (key.properties/*.jks/*.keystore) burada TEKRARLAMIYORUZ (aynı
   kanıtı iki yerde tutmak drift riski taşır); bu kapı SADECE ①'i, tüm
   depoya genelleştirilmiş biçimde ölçer.

⚠️ NE YAKALAMAZ: base64/hex ile gizlenmiş veya parçalanmış sırlar, ve
`.env`/`*.jks` gibi zaten `.gitignore`da olan sınıflar hiç izlenmediği için
`git ls-files` onları hiç görmez — bu KAPSAM DIŞI değil, iki farklı savunma
katmanı (gitignore önler, bu kapı içerik-sızıntısını yakalar).
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

#: (ad, regex, örnek-negatif) — örnek yalnız kendi yorumunda/testinde YAŞAR,
#: taranan dosyalarda değil.
PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("AWS access key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("AWS secret key ataması", re.compile(r"aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}")),
    ("özel anahtar bloğu", re.compile(r"-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----")),
    ("GitHub token", re.compile(r"gh[pousr]_[A-Za-z0-9]{36,}")),
    ("Google API anahtarı", re.compile(r"AIza[0-9A-Za-z_\-]{35}")),
    ("Stripe canlı anahtarı", re.compile(r"sk_live_[0-9a-zA-Z]{24,}")),
    ("Slack token", re.compile(r"xox[baprs]-[0-9A-Za-z-]{10,}")),
    (
        "generic sır ataması (password/secret/api_key=değer)",
        re.compile(
            r"(?i)\b(password|secret|api[_-]?key|access[_-]?token)\b\s*[:=]\s*"
            r"['\"][A-Za-z0-9_\-!@#$%^&*]{12,}['\"]"
        ),
    ),
]

#: Bu dosyanın KENDİSİ desenleri metin olarak taşır — kendi kendini
#: taramaktan muaf (③'ün ölçtüğü tuzağın aynısı: bir kapı kendi örneğini
#: kırmızı yakmamalı).
SELF_EXEMPT = {"tools/secret_scan.py"}


def tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
    )
    return [line for line in out.stdout.splitlines() if line]


def scan() -> list[str]:
    findings: list[str] = []
    for rel in tracked_files():
        if rel in SELF_EXEMPT:
            continue
        path = ROOT / rel
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for name, pattern in PATTERNS:
            for m in pattern.finditer(text):
                line_no = text.count("\n", 0, m.start()) + 1
                findings.append(f"{rel}:{line_no} — {name}: {m.group(0)[:24]}…")
    return findings


def self_test() -> bool:
    ok = True
    cases = [
        ("AKIA" + "A" * 16, "AWS access key", True),
        ("-----BEGIN RSA PRIVATE KEY-----", "özel anahtar bloğu", True),
        ("password = \"hunter2-not-a-real-secret\"", "generic sır ataması", True),
        ("this is just ordinary prose about passwords and secrets", None, False),
        ("const apiKeyLabel = 'API Key';", None, False),
    ]
    for text, expect_name, should_match in cases:
        matched = None
        for name, pattern in PATTERNS:
            if pattern.search(text):
                matched = name
                break
        got = matched is not None
        if got != should_match:
            print(f"⛔ ÖZ-TEST BAŞARISIZ: {text!r} beklenen={should_match} bulunan={got}")
            ok = False
    return ok


def main() -> int:
    if "--self-test" in sys.argv:
        if self_test():
            print("SELF-TEST OK (5 kontrol, 2'si negatif kontrol)")
            return 0
        return 1

    findings = scan()
    if findings:
        print("⛔ OLASI SIR SIZINTISI:")
        for f in findings:
            print(f"   {f}")
        print(f"\n{len(findings)} bulgu — commit'lenmeden ÖNCE incele.")
        return 1

    tracked = tracked_files()
    print(f"✅ sır deseni yok — {len(tracked)} izlenen dosya tarandı, 0 bulgu.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
