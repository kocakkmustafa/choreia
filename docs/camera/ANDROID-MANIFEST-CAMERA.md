# Android manifest ve kamera (CHO-P1-02)

Kamera bayrağı kapalıyken (`motionCameraCoachingAvailable = false`) birleşik Android manifest'inde CAMERA izni ve kamera `uses-feature` satırı yoktur. `motion_camera` eklentisi bunları kendisi eklediği için `android/app/src/main/AndroidManifest.xml` iki öğeyi `tools:node="remove"` ile söker. `test/android_manifest_camera_closed_test.dart` iki öğenin de var ve `remove` taşıdığını doğrular.

Kamera açılırken:

1. `tools:node="remove"` taşıyan iki öğeyi (CAMERA izni, `android.hardware.camera` özelliği) sil; eklenti ikisini yeniden ekler.
2. İstersen açıkça şunu yaz — ama `remove` satırları SİLİNMEDEN bu satırlar işe yaramaz (remove kazanır):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

3. Testi güncelle (bayrak testi zaten açılışta kırılır).
4. Data Safety / izin beyanlarını gözden geçir: `docs/store/account-data-safety-draft.md`, `docs/store/data-safety-matrix.md`.
