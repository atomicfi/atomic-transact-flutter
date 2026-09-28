plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // The conformance suite addresses the app as `<applicationId>/.MainActivity` and
    // `<applicationId>/.TransactCommandReceiver`, so the Kotlin package has to match the applicationId.
    namespace = "com.atomicfi.appiumtestenvironment.flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // `.flutter` keeps it installable alongside the native (`com.atomicfi.appiumtestenvironment`)
        // and React Native (`.rn`) test apps.
        applicationId = "com.atomicfi.appiumtestenvironment.flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // A test app, never published: the debug keys let CI install the release build.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
