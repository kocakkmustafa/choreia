# Choreia

**Global dansları eğitmeninle çalışıyormuş gibi öğreten dans koçu.**

Telefon kamerası kullanıcıyı tam-vücut izler; adımları, zamanlamayı ve formu analiz eder; dans hocan yanındaymış gibi sesli yönlendirir. Yula Motion ailesinin beşinci üyesi — on-device pose + deterministik kural motoru, müzik-beat senkronlu hareket değerlendirmesi.

- 📋 Kapsam özeti: [`docs/choreia-brief.md`](docs/choreia-brief.md) *(tam ürün planı yazılacak — M-009)*
- 📐 Aile sözleşmesi (bağlayıcı): [motion-core → docs/00-AILE-MIMARISI.md](https://github.com/kocakkmustafa/motion-core/blob/main/docs/00-AILE-MIMARISI.md)
- 🧩 Ortak çekirdek: [motion-core](https://github.com/kocakkmustafa/motion-core) (pinli sürüm)

> ⚠️ Hazırlık aşaması — üretim kodu, kurucu "Choreia'ya başlayalım" dediğinde V0 kapısıyla açılır.

## Kurulum (bir kez, klonlandıktan sonra)

```
tool/hooks/install.sh
```

Commit kapısını (`tool/gates.sh`) her commit öncesi otomatik koşan bir
pre-commit hook'una bağlar (C-206). Bu adım atlanırsa `tool/gates.sh` yalnız
elle koşulur — kırmızı bir süitle commit engellenmez.

_Bu repo YULA AI Holding portföyünün parçasıdır._
