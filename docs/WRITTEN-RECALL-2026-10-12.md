# Yazılı hatırlama ve geri bildirim — 12 Ekim 2026

Bu ek, mevcut kaynak derslerini okuma/aktif hatırlama ile çalıştırır. Hareket veya ekipman gerekmez. Öğrenen yazılı cevabı kaynaktan ayrı kurup karşılaştırır. Fiziksel uygunluk, tekniğin doğruluğu, demonstrasyon/lisans ve tam müfredat kabulü verilmez.

| Onaylı alan | Mevcut ders/birim | Yeni okuma | Açık kapsam |
|---|---:|---:|---|
| hiphop | 14 | 2 | Running Man/Roger Rabbit source-version hops need accepted demonstration and competent physical review; musical phrasing needs actual lawful music and learner evidence. |
| salsa | 48 | 2 | Solo count/weight/direction/transition correction requires real learner observation; partner dance is excluded. Music rights and accepted demonstration are open. |
| line | 9 | 2 | Directional travel and weight-transfer technique need real demonstration and review; top-down text/diagrams do not establish support pressure. |
| latin | 8 | 2 | Authored support/count route needs physical and musical review; fitness/calorie outcomes and a full traditional style are not established. |
| shortform | 7 | 2 | Original combinations need demonstrated entry/exit, support and intended musical response; a TikTok-format label grants no choreography/music rights. |

Kaynak dosyaları ve bölüm referansları `lib/app/study_review_content.dart` içindeki `sourceRefs` alanındadır. Eski ders metinleri, süre/doz, sensör eşikleri, fiziksel kabul ve ders ilerlemesi değiştirilmez.

`study_review.dart` durumları ayrı tutar: denenmedi → örneği yeniden oku; belirsiz → kesin terimi/geçişi adlandır ve uygun eğitmene soru hazırla; tek fark → yalnız aynı yazılı noktayı düzeltip kaynağı gizleyerek yeniden hatırla; durdum → bitir, hareket/ekipman görevini tekrar etmeyi önerme. Notlar geçicidir; kalıcı sağlık/hesap/ilerleme kaydı yoktur.

`test/study_review_test.dart` TR/EN dar ekran/büyük metin, kaynak cevabının gizlenip açılması, dört farklı geri bildirim ve çıkışta not/durum atılmasını sınar. Gerçek cihaz, fiziksel öğretim, sensör ve mağaza testi değildir.
