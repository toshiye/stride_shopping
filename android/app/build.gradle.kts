plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.stride_shopping"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ATIVADO: Essencial para flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        
        // Ajustado para 1.8 para máxima compatibilidade com o desugaring
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.stride_shopping"
        
        // Fixado em 21 para suportar Firebase Messaging e Desugaring corretamente
        minSdk = flutter.minSdkVersion 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

// ADICIONADO: Este bloco é o que resolve o erro de compilação que você recebeu
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
