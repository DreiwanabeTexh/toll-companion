import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

android {
    namespace = "com.example.tollcompanion.toll_companion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                val keyAliasVal = keystoreProperties.getProperty("keyAlias")
                val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
                val storeFileVal = keystoreProperties.getProperty("storeFile")
                val storePasswordVal = keystoreProperties.getProperty("storePassword")

                if (keyAliasVal.isNullOrBlank() || keyPasswordVal.isNullOrBlank() || storeFileVal.isNullOrBlank() || storePasswordVal.isNullOrBlank()) {
                    throw GradleException("key.properties is missing required signing properties (keyAlias, keyPassword, storeFile, storePassword). Release build aborted.")
                }

                val storeFileObj = file(storeFileVal)
                if (!storeFileObj.exists()) {
                    throw GradleException("Release keystore file specified in key.properties does not exist: ${storeFileObj.absolutePath}. Release build aborted.")
                }

                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = storeFileObj
                storePassword = storePasswordVal
            } else {
                throw GradleException("android/key.properties file not found. Release builds require a configured private release keystore. Fallback signing with debug keys is prohibited for security compliance.")
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.tollcompanion.toll_companion"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
