# Choreia · internet verisi kapsamı ve ilk pilot · 17 Ekim 2026

Durum: **hazırlık tamam, lisans/erişim bekliyor; eğitim başlamadı**.
Kullanıcı özel/profesyonel çekim sağlayamayacağını belirterek internet
verisiyle eğitim istedi. Önceki yalnız kullanıcı çekimi bekleme varsayımı
bu araştırma için güncellendi. Mevcut uygulama değerlendirmesi hâlâ kapalı;
bu belge veri veya model kabulü vermez.

## Kapsam · beş alan, altı kurs, 86 birim

Aşağıdaki eşleme uygulama kaynakları ile yayımlanmış veri açıklamasını
karşılaştırır. Gerçek take/annotation dosyası görülmedi; **0 doğrulanmış
birebir ders eşleşmesi**, veride gerçekten sıfır eşleşme bulunduğu demek değildir.
[86 birimin tam kimlik/kaynak eşlemesi](2026-10-17-curriculum-scope-86.json).

| Uygulama alanı | Birim | Ego-Exo4D için aday kapsam | Henüz kanıtlanmayan |
|---|---:|---|---|
| HipHop Foundations | 6 temel +8 beceri | Genel görünür hareket/koordinasyon transferi | HipHop, Bounce, Rock, Running Man, Roger Rabbit için birebir görev/uzman etiketi |
| Salsa Shines | 48 | En güçlü ilk aday: makalenin Uniandes salsa akademisi, başlangıç koreografisi ve dış kamera açıklaması | Solo/On1 eşliği, sayım/beat, SuzyQ/Jazz square ve her dersin etiket mevcudiyeti |
| Line Dance | 9 | Genel ayak yolu/yön transferi araştırılabilir | Line dance, grapevine, çok duvarlı özgün 24 sayım ve geri giriş etiketleri |
| Latin Fusion Fitness | 8 | Makalede Latin dans ailesi belirtilir | Bu fitness akışı, özgün örüntüler, yük/yoğunluk/güvenlik veya Cumbia doğruluğu |
| Özgün kısa-form | 7 | Genel hareket dizisi temsili araştırılabilir | Uygulamaya ait özgün motif/notasyonun aynı veri görevi olduğu veya ustalık etiketi |

Resmî [ana sayfa](https://ego-exo4d-data.org/) Dance için 728 take,
93 katılımcı ve 7 saha gösterir; bu sayılar etiketli ders kapsamı değildir.
[Makale §8.8/§8.11](https://arxiv.org/html/2311.18259), Salsa ve Latin gibi
dans ailelerini açıklar. Makaledeki toplama sayıları ile güncel release
sayısını toplamayacağız; erişimden sonra tek release ve metadata hash'i
sabitlenecek. Tam beş alan öğretim hedefi korunur; bu pilot o hedefin kabulü değildir.

## İlk pilot · tek salsa koreografisi, tek dış görünüş

**Araştırma hedefi:** Aynı koreografi ve aynı gerçek uzman için,
whole-take uzman puanından sınırlı bir göreli icra kalitesi modeli öğrenmek.
Adımın doğru olduğu, fiziksel destek/ağırlık, On1 zamanlaması veya ustalık
sonucu üretilmez. Bu seçim, eldeki etiketin seviyesine uyar; take puanı kare
etiketi gibi çoğaltılmaz.

1. Kullanıcının kabul ettiği final lisans ve erişim geldikten sonra,
   yayımlanmış başlangıç koreografisinin exact `task_id`/koreografi sürümü,
   solo durumu, dış kamera ve gerçek uzman puanı varlığı kontrol edilir.
   Henüz seçilmiş UID veya indirilmiş kayıt yok.
2. Hedef öneri: en az 12 bağımsız kişi/çekim bileşeninden ikişer take,
   en fazla24 take. Aynı uzman için sayısal hedef çeşitliliği ve yeterli
   etiket yoksa supervised eğitim durur; eksik etiket uydurulmaz.
3. Katılımcı alias'ı, capture/source recording ve aynı kaynak hash'i
   bağlantılarının **bağlı bileşenleri** oluşturulur. Ortak kişi veya ortak
   çekim varsa bütün takes/kamera açıları aynı bölümde kalır. 8/2/2 bileşen
   train/validation/test önerilir; bağlı bileşen bölünerek sayı tamamlanmaz.
4. Her take için tek, karşılaştırılabilir, bütün bedeni/ayakları gösteren
   tavan dışı dış kamera kullanılır. [Metadata](https://docs.ego-exo4d-data.org/data/metadata/)
   `is_ego=false`, görünürlük ve PTS bilgisi doğrulanır; `camXX` adı tek başına
   yeterli değildir. Seçim performans puanına/test sonucuna bakarak yapılmaz.
   Seçilmemiş açılar da aynı bölüm kimliğini taşır.
5. Mevcut `pose_landmarker_full/float16/1` backbone donuk tutulur.
   Önceden belirlenmiş az sayıda normalize2D poz/hız/missingness özetinden
   CPU ridge başlığı önerilir. Ölçekleme/imputation yalnız train'de öğrenilir.
   Ham RGB, yüz, kimlik veya audio özelliği kullanılmaz; bu domain kaymasını
   ya da kaynak müzik haklarını otomatik çözmez.
6. Train-median baseline'a karşı take/kişi seviyesinde MAE, izin verdiğinde
   rater-içi sıra ilişkisi, coverage ve grup-bootstrap belirsizliği raporlanır.
   Mevcut gerçek etiketlerin hiçbiri görülmediği için başarı eşiği veya elde
   edilmiş sonuç yok. Sadece tek koreografi/site kapsamında değerlendirilir.
   İyileşme çıksa bile ürün dans doğruluğu kabulü sayılmaz.

Resmî sealed test etiketleri istenmez. Uygun train/val kaynak havuzundan
oluşturulacak iç holdout önceden dondurulur; resmî bölüm sınırıyla kişi/çekim
çakışması varsa grup dışlanır. Shared Core'un test-açma kaydı tek yazarı
üzerinden kullanılır; holdout görüldükten sonra ayar yapılmaz.

**Yalnız sonraki koşu için sınır önerisi:** metadata/seçilmiş annotation
128MiB, video2GiB, en fazla24 take ve take başına tek dış kamera;
10FPS örnekleme,2CPU thread/30dakika üst sınır. Bunlar indirme/koşu onayı
veya ölçülmüş süre değildir. [CLI](https://docs.ego-exo4d-data.org/download/)
varsayılanı çok TB'dir; defaults/all kullanılmaz. `--parts`, `--benchmarks`,
`--uids`, `--views exo`, `--release` filtreleri ancak gerçek manifest/CLI
sürümüyle doğrulanır. `--views exo` bütün dış kameraları indirebilir; tek
dosya seçimi ve byte hesabı kanıtlanmadan video indirilmez. Sınır aşılırsa
otomatik artırma yok. Bu tur indirme, optimizer veya GPU koşusu yapılmadı.

## Gerçek uzman ile yapay etiket ayrımı

[Expert commentary](https://docs.ego-exo4d-data.org/annotations/expert_commentary/)
insan uzmanın sesini, uzman kimliğini ve take için verdiği1–10 puanı ayırır.
Puan skalası uzmana bağlıdır; farklı uzman puanları kalibrasyonsuz birleştirilmez.
Birleştirilmiş transcript dosyası puanı içermediğinden ilgili uzman
`data.json` kaydı ve varlık/hash doğrulaması gerekir.

| Kaynak | Kabulde nasıl kullanılacak? |
|---|---|
| Orijinal uzman sesi, kimliği, take puanı ve gerekçesi | İnsan expert kaynağı olarak ayrı provenance; bu pilotun olası gerçek hedefi |
| Whisper transcript | Otomatik ASR; hata/uyumsuzluk kontrol edilmeden birebir insan etiketi sayılmaz |
| [Good executions/tips](https://docs.ego-exo4d-data.org/annotations/proficiency_estimation/) | İşaretli an/yorum; otomatik bütün-kare veya belirli adım doğruluğu etiketi yapılmaz |
| Novice/Early Expert vb. demonstrator sınıfı | Kişi seviyesi farklı hedef; o take'in icra puanı yerine geçirilmez |
| Model pozu/triangulation/pseudo-GT | Kökeni ayrılır; insan doğru-hareket, temas veya yük etiketi değildir |
| LLM özeti/çeviri, sentetik klip/bozma | Açıkça yapay yardımcı veri; gerçek uzman veya değerlendirme ground truth'u olmaz |

Eksik yorum “yanlış hareket” değildir. Ses kullanmamak, orijinal MP4'te
ses bulunmadığı veya müzik hakkına sahip olunduğu şeklinde metadata
üretmeye izin vermez. Sessiz türev de ancak kabul edilmiş sözleşmenin
izin verdiği amaçta ve orijinal hash/provenance korunarak oluşturulur.

## Lisans/erişim · gereken en küçük kullanıcı adımı

[Resmî başvuru](https://ego4d.dev/request/ego-exo4d) mevcut Chrome'da normal
salt okunur açıldı. Başlangıçta Individual/Organization seçimi; First name,
Last name, Email, Home Address, City, State/Province/County, Country
alanları görüldü. Organization seçilmedi; o dalın ek alanları bilinmiyor.
HTML required niteliğinin olmaması alanların opsiyonel olduğunu kanıtlamaz.
Başlangıçta giriş veya imza alanı yoktu; sonraki HelloSign aşaması görülmedi.
Kişisel bilgi okunmadı/girilmedi, form gönderilmedi, kabul/imza yapılmadı.

**Kullanıcı bizzat** doğru lisans tarafını seçerek bu formu tamamlamalı ve
gelecek HelloSign final sözleşmelerini amaç/ticari türev kapsamı bakımından
inceleyip uygun bulursa imzalamalı. [Yönerge](https://docs.ego-exo4d-data.org/getting-started/)
ücretsiz veri erişimi ve onay sonrasında geçici credential sürecini anlatır.
Credential sohbet/repoya konmaz; yeni hesabı veya credential'ı biz oluşturmadık.
Erişimden sonra ana sohbet önce sınırlı metadata/annotation alımını koordine eder.

[PDF](https://ego4d-data.org/pdfs/Ego-Exo4D-Model-License.pdf) açıkça
**DRAFT FOR REVIEW** durumunda. Ticari geliştirme/türev model maddeleri
bulunması, final sözleşme kabulü veya ham görüntü/müziği uygulamada dağıtma
izni değildir. Corpus eğitim adayı ile mağazadaki gösterim medyası ayrı
kapılardır; gösterim kataloğu boş kalır.

[AIST++ annotations](https://google.github.io/aistplusplus_dataset/factsfigures.html)
CC BY4.0'dır; [video/müzik ayrı AIST şartlarına](https://aistdancedb.ongaaccel.jp/terms_of_use/)
bağlı ve ticari kullanım için ön yazılı izin gerektirir. AIST++ bütünü
serbest ticari kaynak sayılmadı, bu pilotta kullanılmıyor. H-Dance bu tur
çelişkili kaynak koşulları nedeniyle dışlandı.

## Core tek yazarına arayüz önerisi

Lissom sahibi mevcut pipeline'ın tek yazarıdır. Bu uygulamada ikinci
pipeline kurulmuyor. Ek external-license provenance sidecar'ında dataset/release,
metadata hash'i, özel final lisans kanıtının referans/hash'i, kişi alias,
capture/take/source/camera/PTS, gerçek dosya hash/byte, expert/etiket kökeni,
train/eval/demo/music amaç izinleri ve bölüm/test-açma kaydı istenir.
İlgili alanlar Core sahibince mevcut intake'e uyarlanır; dış veri kullanıcı
çekimi veya otomatik verilmiş consent/no-bystander/music izni gibi sunulmaz.
Paylaşılan Core dosyası/pini, uygulama runtime'ı, signed paket, CI veya
mağaza değiştirilmedi. Model/kalibrasyon aktivasyonu ayrı kabul ve sürüm gerektirir.
