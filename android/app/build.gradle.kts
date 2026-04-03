plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.jobportal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        // "create" ki jagah "getByName" use karein
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    compileOptions {
        // 👇 Kotlin DSL mein 'is' lagana zaroori hai
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // 👇 Naya tareeka jvmTarget set karne ka
//        freeCompilerArgs += listOf("-P", "plugin:imaging.cm-target=1.8")
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.jobportal"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 👇 Kotlin DSL mein brackets aur quotes ekdum sahi hone chahiye
           coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
            implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
            implementation("com.google.firebase:firebase-analytics")
}