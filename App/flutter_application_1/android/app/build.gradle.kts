plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        // 🟢 แก้ไข 1: เปลี่ยนจาก flutter.minSdkVersion เป็น 23 หรือ 24 ไปเลย เพื่อให้รองรับ Maps & Firebase
        minSdk = 24 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 🟢 แก้ไข 2: เพิ่มบรรทัดนี้เพื่อเปิดใช้งาน Multidex ที่คุณใส่ไว้ใน dependencies
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ป้องกัน Google Maps Crash ทันทีที่โหลดบน Emulator เก่า (บังคับโหลดไลบรารี)
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    // ป้องกันปัญหา Multidex สำหรับแอพที่ใช้ Firebase + Google Maps
    implementation("androidx.multidex:multidex:2.0.1")
}
