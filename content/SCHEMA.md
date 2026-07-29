# Choreia — İçerik Şeması (v1)

**Bağlayıcı ilke (plan §7):** *Yeni stil = yeni içerik paketi, kod değişimi DEĞİL.* Adım tanımı, faz makinesi, eşikler, sayım metni ve hata kodları burada yaşar; motor bunları yorumlar. Bir stil eklemek derleme gerektirmez.

```
content/
  styles/
    <style_id>/
      style.json          # stil meta + seviyeler + ders sırası
      steps/<step_id>.json
      combos/<combo_id>.json
```

## Ortak alanlar

Her dosya `schemaVersion` taşır. Sürüm yükseltmesi = migration notu + eski sürümün okunabilir kalması.

## `style.json`

| Alan | Anlam |
|---|---|
| `id` | dosya yolu ile aynı, `snake_case` |
| `name` | `{en: ...}` — ürün dili İngilizce, i18n anahtarı baştan |
| `countSystem` | `8count` · `salsa_123_567` — sayım metinlerini ve beat eşlemesini sürer |
| `bpmRange` | `[min, max]` — ders müziği seçimini ve tempo kapısını sınırlar |
| `honesty` | **ZORUNLU** — `{measured[], notMeasured[]}`; K10'un makine-okur hâli (aşağıda) |
| `levels[]` | `{level, name, unlockRule, lessons[]}` |
| `unlockRule` | ölçülebilir kriter; **ders tamamlamak seviye atlatmaz** (plan §7). Seviyede skorlanan ders YOKSA `null` olabilir — o zaman `unlockRuleNote` zorunlu |

### `honesty` — K10'un makine-okur hâli (ZORUNLU)

**Her stil neyi skorladığını ve neyi BİLEREK skorlamadığını, gerekçesiyle beyan eder.** Ostinato'nun disiplin-düzeyi `honesty` bloğunun Choreia karşılığı.

| Alan | Kural |
|---|---|
| `measured[]` | Uygulamanın skorlamaya izinli olduğu şeyler. **Buraya yazılmayan hiçbir şey skorlanamaz.** BOŞ olabilir (hiçbir şeyi henüz skorlamayan stil dürüst bir durumdur) — ama boşsa `measuredNote` neden boş olduğunu söyler |
| `notMeasured[]` | Gösterilen/öğretilen ama skorlanmayan şeyler, her biri **ölçülmüş** gerekçesiyle. Boş olamaz: hiçbir stil her şeyi ölçmez, boş liste "soru sorulmamış" demektir |

Gerekçe biçimi bağlayıcı: *"eğitmenler 11-58° ayrışıyor"* geçerli, *"bu zor"* değil. `notMeasured` girdisi bir politika tercihi değil, bir ölçüm sonucudur.

### `levels[].lessons[]` — ders nesnesi

Ders **çıplak id string'i OLAMAZ**; durumunu beyan eder, yoksa skorlanmayan bir ders skorlanıyor sanılır.

| Alan | Anlam |
|---|---|
| `id` · `displayName` | ders kimliği + `{en: ...}` |
| `step` | ilgili `steps/<id>.json` (varsa; demo-only derslerde olmayabilir) |
| `scored` | **ZORUNLU bool.** `true` ise `_whyUnlocked` gerekçesi beklenir |
| `scoredWhat[]` / `notScoredWhat[]` | skorlu derste kullanıcıya ne söylendiği |
| `status: "locked"` + `lockedReason` | ölçüm henüz YOK → ders kapalı. Gerekçe **kullanıcı dilinde**, ve eksik ÖLÇÜMÜN adıyla (`blockedBy` makine-okur karşılığı) |
| `demoOnly: true` + `demoOnlyReason` | **K10:** ölçülemeyen hareket ELENMEZ, demo-only işaretlenir ve nedeni kullanıcıya söylenir. `evidence` alanı gerekçenin ölçüm dayanağını gösterir |

### Statü kafesi — `library.json` (M-F-123, aile standardı)

Stil statüsü ders durumlarına **İKİ YÖNLÜ** bağlıdır; `validate_content.py` her iki yönü de kapı olarak koşar.

| Statü | Şart |
|---|---|
| `live` | ≥1 `scored` ders **ve** `honesty.measured` boş değil |
| `demoOpen` | ≥1 `demoOnly` ders **ve** `scored` ders sayısı 0 |
| `comingSoon` | açılabilir (`demoOnly`) ders YOK (diskte style paketi olmaması da buraya girer) |

**Açılabilir = `demoOnly`.** `locked` ders AÇILAMAZ (kilit görünür, açılmaz), bu yüzden yalnız locked ders taşıyan stil `demoOpen` **değildir**.

**Neden iki yönlü:** aşırı-iddia (`live` ama hiçbir şey skorlanmıyor) ile eksik-iddia (`comingSoon` ama kullanıcı dersi açabiliyor) aynı kusurun iki yönü — kayıt defterinin, içeriğin söylemediği bir şeyi söylemesi. Fazla-satmayı engelleyen disiplin eksik-satmayı da engeller.

⚠️ **Statü ≠ ship-hazırlığı.** Kafes "kullanıcı bu stili gördüğünde ne bulacak"ı tanımlar; ship kapıları (ör. salsa'nın `bpmStatus: DISPUTED`) ayrı eksendir. Bir stil `live` olup hâlâ yayına çıkamaz.

**`library.json` stil-düzeyi `demoOnly` dizisi bir PLAN NOTU'dur**, ders durumu değil — kafes kararı yalnız `style.json`'daki gerçek `lessons[]` durumlarına bakar.

**`locked` ≠ `demoOnly`:** `locked` = ölçüm eksik, gelecekte açılabilir (geçici). `demoOnly` = ölçüm yapısal olarak mümkün değil ya da anlamsız (kalıcı; groove, kol stili, ayak-ucu zamanlaması). İkisini karıştırmak, çözülebilir bir eksiği çözülemez göstermek (ya da tersi) olur.

Skorlanmayan bir ders `locked` ya da `demoOnly` olmak ZORUNDA — ikisi de değilse gerekçesiz-skorsuz ders olur, `validate_content.py` bunu reddeder.

## `steps/<id>.json`

| Alan | Anlam |
|---|---|
| `beats` | adımın kaç beat sürdüğü |
| `countLabels[]` | kullanıcıya söylenen sayım (`"1"`, `"2"`, `"a"`, `"&"`) — sesli koç bunu okur |
| `measurability` | **CV-ölçülebilirlik derecesi** (aşağıda) — hangi adımın V1'e gireceğini bu belirler |
| `scoring.focusJoints[]` | skorlanan eklemler (`motion_core` `StandardJoints` id'leri) |
| `scoring.freeJoints[]` | **bilinçli skorlanmayan** eklemler — stil/ifade alanı |
| `phases[]` | faz makinesi: `{id, enter, exit?, timeoutMs?, minDurationMs?, requiredLandmarks[]}` |
| `scoredMoments[]` | beat-kilitli aksanlar: `{id, phase, beat, label}` — zamanlama YALNIZ bunlarda ölçülür |
| `errors[]` | `{code, severity, detect, evidence, relatedDrill}` |
| `reference` | `{requiredTakes, collectedTakes, status}` — ≥3 (tercihen 6) bağımsız eğitmen (katalog §6.0) |

### `measurability.tier` — V1 kapısı

R1'in CV-risk bulgusuna dayanır: düşük-genlikli tek-segment izolasyonlar poz modellerinin zayıf olduğu alandır; ayak-ucu temas zamanlaması ise markerless tek kamerada **en düşük güvenli** noktalar arasındadır.

| Tier | Tanım | V1 |
|---|---|---|
| **A** | Büyük genlikli, çok-segmentli, ayak-ucu temasına bağlı değil | ✅ girer |
| **B** | Orta genlik veya tek-segment baskın; ölçülebilir ama eşik hassas | ⚠️ pilot ölçümünden sonra |
| **C** | Düşük-genlikli izolasyon veya ayak-ucu temas zamanlamasına dayalı | ❌ V1 dışı |

**Bağlayıcı:** Tier C adım V1 müfredatına alınmaz. Ölçemediğimiz bir şeyi öğretip skorlamak, plan §13.2'nin ("düşük güvende hüküm yok") içerik seviyesindeki karşılığıdır.

### Hata tanımı — gözlemlenebilirlik şartı

**Bir `errors[]` girdisi, landmark'lardan ölçülebilir bir koşula bağlanmak ZORUNDADIR.**

R1'in hip-hop hata listesi bu şartı karşılamıyor: "temelleri atlamak", "sabırsız olmak", "müziği kafayla analiz etmek" pedagojik öğütlerdir — doğru olabilirler ama **kameradan görülemezler**. Bunlar ders metnine girer, hata koduna girmez.

Karşılaştırma için ölçülebilir olan: "ağırlık aktarılmadı" (yük taşıyan bacağın diz/kalça açısı değişmedi), "beat'te yukarı çıkmış" (bounce fazı ters), "gövde çökmüş" (diz yerine gövde bükülüyor).

### Kimlik anlaşmazlığı — bağımsız V1-dışı bırakma gerekçesi (C-038)

**Kaynaklar bir adımın ne olduğunda anlaşamıyorsa, o adım V1'e alınmaz — genlik/tier analizinden bağımsız olarak.**

Gerekçe: topluluk dokümantasyonu *"bu hangi harekettir"* sorusunda ayrışıyorsa, elimizde tek bir kodlanabilir hareket değil, sahneye ve döneme göre farklı şeylere takılan **gevşek bir etiket** vardır. Böyle bir adımı "doğru" diye öğretmek, kullanıcıyı keyfî olarak seçtiğimiz bir versiyona göre skorlamak demektir.

Gözlenen örnekler: Reebok (üç kaynak, üç farklı hareket) · Wop (üç kaynak, üç farklı ana sürücü) · Monastery (ayak-topuk illüzyonu mu, mekân-adı/Chicken-Head benzeri mi) · Gucci (bağımsız tarifi yok; Reebok/Troop/Skeletor ile aynı aile).

**Bu kuralı uygulamak için ayrı bir araç gerekmiyor.** Referans hattı zaten ölçüyor: eğitmenler ayrışıyorsa `CanonicalReference` dispersiyonu yükselir ve `unreliableJoints()` o eklemleri işaretler. Aynalamayı konsensüsle çözen mekanizma, *"bu tek bir hareket mi"* sorusunu da aynı veriyle cevaplıyor.

**İlgili tuzak — isim çeşitliliği ≠ hareket çeşitliliği:** Bankhead Bounce ≈ BK Bounce (kaynağın kendi ifadesiyle "aynı yapı", yalnız köken farklı) ve Gucci ≈ Reebok/Troop/Skeletor. Bunlar müfredat adım sayısına **ayrı ayrı sayılamaz**; ayrı öğretip aynı skorlamak dürüstlük ihlalidir.
