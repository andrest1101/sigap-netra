import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sigap_netra_app"
    compileSdk = flutter.compileSdkVersion
    // Plugin Firebase (cloud_firestore/firebase_auth/firebase_core) dibangun
    // dengan NDK 27; `flutter.ndkVersion` masih 26.x dan memicu peringatan
    // mismatch. NDK kompatibel ke belakang, jadi pakai yang tertinggi.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications memakai API Java 8+ yang perlu
        // desugaring agar tetap berjalan di minSdk 23.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sigap_netra_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 23 = minimum `firebase_auth`; Android target utama project ini.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// KGP 2.3 menghapus `kotlinOptions` (kini error); DSL resmi = compilerOptions.
kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}
