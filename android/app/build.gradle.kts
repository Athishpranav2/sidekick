import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase plugin
}

android {
    namespace = "com.sidekick.campus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // ✅ Set explicitly

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sidekick.campus"
        minSdk = 23 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // ✅ Optional safety
    }

    signingConfigs {
        create("release") {
            val kp = Properties()
            val kpFile = rootProject.file("key.properties")
            if (kpFile.exists()) {
                kp.load(FileInputStream(kpFile))
            }
            val sfProp = kp.getProperty("storeFile") ?: "release-key.jks"
            val sanitized = if (sfProp.startsWith("app/")) sfProp.removePrefix("app/") else sfProp
            storeFile = file(sanitized)
            storePassword = kp.getProperty("storePassword")
            keyAlias = kp.getProperty("keyAlias")
            keyPassword = kp.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.3.1"))
    implementation("com.google.firebase:firebase-database")
    // Add more Firebase SDKs as needed:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}
