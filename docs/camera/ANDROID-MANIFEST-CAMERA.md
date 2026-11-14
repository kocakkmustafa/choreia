# Android manifest ve kamera (CHO-P1-02)

Kamera bayrağı kapalıyken (`motionCameraCoachingAvailable = false`) birleşik Android manifest'inde CAMERA izni ve kamera `uses-feature` satırı yoktur. `motion_camera` eklentisi bunları kendisi eklediği için `android/app/src/main/AndroidManifest.xml` iki satırı `tools:node="remove"` ile söker. `test/android_manifest_camera_closed_test.dart` bunu doğrular.

Kamera açılırken: bu iki `tools:node="remove"` satırını sil (eklenti izni ve özelliği yeniden ekler); istersen açıkça şunu da yazabilirsin:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Sonra testi güncelle, Play Data Safety ve izin açıklamasını gözden geçir.
