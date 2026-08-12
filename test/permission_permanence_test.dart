import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// **`isRestricted` DAVRANIŞLA sürülüyor — varlıkla değil.**
///
/// Niye bu dosya var
/// -----------------
/// C-222'de `askOsPermanentlyDenied` Ostinato'nun kuralını aldı:
/// `isPermanentlyDenied || isRestricted`. `isRestricted` yarısı o gün
/// EKLENDİ ve HİÇ KOŞULMADI — kaynak taraması onu "var" gösterirdi, hiçbir
/// test onu SÜRMEZDİ. Lissom aynı sabah (11:00, L-283) tam bu sınıfı kendi
/// hattında ölçtü: *"kodda vardı, hiç koşulmamıştı"*, ve `|| isRestricted`
/// düşürüldüğünde YALNIZ yeni testi kırmızı yandı — o test olmasa sessiz
/// regresyon geçerdi.
///
/// Niye `permanentlyDeniedProbe` dikişi KULLANILMIYOR
/// --------------------------------------------------
/// Çünkü o dikiş bu fonksiyonun YERİNE geçer. Enjekte edilmiş bir probe ile
/// yazılan test, içindeki kural hakkında HİÇBİR ŞEY kanıtlamaz — sahtenin
/// gerçeğin kuralını uygulamaması sınıfının aynısı (C-218). Burada platform
/// KANALI stub'lanıyor ve gerçek zincir sürülüyor:
/// kanal → `permission_handler` → bizim kuralımız.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // permission_handler'ın gerçek kanalı ve metodu — pub-cache'ten OKUNDU,
  // ezberden yazılmadı (`method_channel_permission_handler.dart:10,18`).
  const MethodChannel channel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  /// `PermissionStatus.statusByValue`'nun sırası, paketin kendi kaynağından:
  /// 0 denied · 1 granted · 2 restricted · 3 limited · 4 permanentlyDenied ·
  /// 5 provisional. Bu sayılar UYDURULMADI; sıra değişirse testler düşer ve
  /// düşmesi doğrudur — kural o sıraya bağlı.
  const int denied = 0;
  const int granted = 1;
  const int restricted = 2;
  const int permanentlyDenied = 4;

  void answerWith(int status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'checkPermissionStatus') return status;
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('kalıcı ret kuralı — OS ne derse', () {
    test('restricted KALICIDIR (MDM/ebeveyn denetimi — diyalog HİÇ çıkmaz)',
        () async {
      answerWith(restricted);
      expect(await askOsPermanentlyDenied(), isTrue,
          reason: 'restricted kalıcı sayılmıyor — eski "ikinci ret" sezgisinin '
              'ilkece göremediği vaka geri geldi');
    });

    test('permanentlyDenied KALICIDIR', () async {
      answerWith(permanentlyDenied);
      expect(await askOsPermanentlyDenied(), isTrue);
    });

    // NEGATİF İKİZLER — bu ikisi olmadan yukarıdakiler `=> true` diyen bir
    // fonksiyonda da geçerdi.
    test('denied kalıcı DEĞİLDİR — "tekrar dene" hâlâ çalışır', () async {
      answerWith(denied);
      expect(await askOsPermanentlyDenied(), isFalse,
          reason: 'geçici ret kalıcı sayılırsa kullanıcı ihtiyacı olmayan bir '
              'ayar gezisine gönderilir');
    });

    test('granted kalıcı DEĞİLDİR', () async {
      answerWith(granted);
      expect(await askOsPermanentlyDenied(), isFalse);
    });
  });
}
