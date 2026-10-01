@file:Suppress("DEPRECATION")

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ANDROID RELEASE İMZASI — sessiz debug-imzası KALDIRILDI (jablab J-215 deseni).
//
// ## Ne vardı, neden kusurdu
//
// Flutter şablonu `release { signingConfig = signingConfigs.getByName("debug") }`
// bırakıyordu. Bu, `flutter build appbundle` komutunu ÇALIŞTIRIR ve **debug
// anahtarıyla imzalanmış** bir artefakt üretir — Play bunu REDDEDER. Kusurun
// sınıfı bu ailede tanıdık: **sessiz-hiçlik.** Komut başarılı görünür, dosya
// oluşur, ve yanlış olduğu ancak Play'e yüklendiğinde anlaşılır.
//
// motion-core'un beş-tüketici consumer-matrix taramasında (2026-08-19)
// choreia bu satırı taşıyan TEK app'ti — lissom/gravita/jablab zaten sert
// duruyordu, ostinato en azından uyarıyordu (ayrıca sert duracak şekilde
// güncellendi). Choreia beşin en açık yüzeyiydi.
//
// ## Bu dosyanın YAPTIĞI ve YAPMADIĞI
//
// * ⛔ **Keystore ÜRETMEZ.** İmza kimliği kurucunun kalemidir ve bir SIRDIR;
//   yeri `~/.secrets/yula/`, workspace'e ASLA girmez.
// * ✅ **Yokluğu GÜRÜLTÜLÜ yapar.** `key.properties` yoksa release görevleri
//   *başlamadan* adıyla durur. Bugün sessizce üretilip Play'de reddedilecek
//   bir artefaktı, yerelde ve gerekçesiyle durduruyoruz.
// * ✅ **Debug'a DOKUNMAZ.** `flutter run`/`flutter test`/commit kapısı
//   etkilenmez — kapı yalnız release görev grafiğinde ateşlenir.
val keystorePropsFile: File = rootProject.file("key.properties")
val hasKeystore: Boolean = keystorePropsFile.exists()
val keystoreProps = Properties().apply {
    if (hasKeystore) FileInputStream(keystorePropsFile).use { load(it) }
}

// CHO-P0-002 EKİ — bilerek debug-imzalı KOD YOLU kanıtı (gravita G-192 +
// lissom emsali; jablab J-215'in kendisinde bu kaçış YOK).
//
// Yukarıdaki kapı doğru: anahtar yoksa release SESSİZCE üretilmemeli. Ama
// roadmap'in kendisi CI'da ve yerel doğrulamada `flutter build appbundle
// --release` koşumunu İSTİYOR — ve CI runner'ında gerçek keystore YOK ve
// OLMAMALI (imza kimliği hesap-sahibinin sırrı). İki gerçek çelişmiyor:
// "sessizce debug'a düşme" ile "isteyerek, adıyla, debug anahtarıyla derle"
// ayrı şeyler. Bayrak yalnız `-PallowDebugSigning=true` ile AÇIKÇA
// istendiğinde devreye girer; varsayılan davranış (bayraksız) DEĞİŞMEDİ.
val allowDebugSigning: Boolean =
    (project.findProperty("allowDebugSigning") as String?) == "true"

android {
    namespace = "com.yulalab.choreia"
    compileSdk = 37
    buildToolsVersion = "37.0.0"
    ndkVersion = "30.0.16248370"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yulalab.choreia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Yalnız gerçek anahtar VARSA tanımlanır. Boş/yer-tutucu bir release
        // config tanımlamak, olmayan bir imzayı VARMIŞ gibi gösterirdi.
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
                storeFile = keystoreProps.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // ⚠️ Üç yol, en güçlüden en zayıfa: gerçek anahtar → bilerek-
            // debug (yalnız bayrakla) → `null` (aşağıdaki kapı durdurur).
            // `null` hâlâ VARSAYILAN — bayrak yoksa davranış AYNI.
            signingConfig = when {
                hasKeystore -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// ⛔ KAPI — release, imzasız SESSİZCE üretilemez.
//
// `taskGraph.whenReady` seçildi çünkü yapılandırma anında fırlatmak DEBUG'ı da
// kırardı; kusur yalnız release yolunda ve kapı da yalnız orada ötmeli.
if (!hasKeystore) {
    gradle.taskGraph.whenReady {
        val releaseTasks = allTasks.filter { task ->
            task.name.contains("Release") &&
                listOf("assemble", "bundle", "package", "install").any { task.name.startsWith(it) }
        }
        if (releaseTasks.isEmpty()) return@whenReady

        if (allowDebugSigning) {
            // Bilerek istendi — durdurmuyoruz, ama SESSİZ de değil.
            logger.warn(
                "⚠️  RELEASE DEBUG ANAHTARIYLA İMZALANIYOR (-PallowDebugSigning=true). " +
                    "Bu artefakt Play'e YÜKLENEMEZ — yalnız kod-yolu/CI kanıtı içindir."
            )
            return@whenReady
        }

        throw GradleException(
            """
            |
            |╔══════════════════════════════════════════════════════════════╗
            |║  ANDROID RELEASE İMZASI YOK — build DURDURULDU (J-215 deseni) ║
            |╚══════════════════════════════════════════════════════════════╝
            |
            |İstenen görev: ${releaseTasks.joinToString(", ") { it.name }}
            |
            |NEDEN DURDU: `android/key.properties` yok. Flutter şablonu bu
            |durumda release'i DEBUG anahtarıyla imzalar; o artefakt derlenir,
            |dosya oluşur ve Play tarafından REDDEDİLİR. Sessizce yanlış bir
            |şey üretmektense burada, adıyla duruyoruz.
            |
            |NE GEREKİYOR (kurucu kalemi — imza kimliği bir SIRDIR):
            |  1. Keystore kurucuda üretilir/saklanır: ~/.secrets/yula/
            |     ⛔ Keystore ve parolalar bu depoya ASLA girmez.
            |  2. `android/key.properties` (git-dışı, .gitignore'da):
            |       storeFile=/Users/<sen>/.secrets/yula/choreia-release.jks
            |       storePassword=...
            |       keyAlias=...
            |       keyPassword=...
            |
            |BİLEREK debug-imzalı, YALNIZ KOD-YOLU kanıtı (CI/yerel deneme):
            |  ./gradlew :app:assembleRelease -PallowDebugSigning=true
            |
            |Debug etkilenmedi: `flutter run`, `flutter test` ve commit kapısı
            |bu kapıya hiç çarpmaz.
            """.trimMargin()
        )
    }
}

flutter {
    source = "../.."
}
