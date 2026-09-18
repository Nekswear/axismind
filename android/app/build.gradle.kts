plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // <--- Вот эта строчка обязана здесь стоять
}

android {
    namespace = "com.axismind.app" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Включаем поддержку новых возможностей Java для старых версий Android
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.axismind.app" 
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Включаем MultiDex для преодоления лимита в 64K методов
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("upload-keystore.jks")
            storePassword = "Yc.IVfV8X6syUUh8up32eDhk%JgktCuS1.AtJMmV%aHGVxSDAWJp8NKTP9xSAp#l"
            keyAlias = "upload"
            keyPassword = "PNncq%QxXQP7NMHVIClDGBBlf_wBc=SidhF5GHRy%eBigs3HXqEkmvDrkVwDnHW="
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Зависимость для работы desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}