import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
if (keystorePropertiesFile.exists()) {
    requiredSigningKeys.forEach { key ->
        require(keystoreProperties.getProperty(key)?.isNotBlank() == true) {
            "Missing Android release signing property: $key"
        }
    }
    require(file(keystoreProperties.getProperty("storeFile")).isFile) {
        "Android release keystore does not exist."
    }
}
if (releaseTaskRequested) {
    require(keystorePropertiesFile.exists()) {
        "Release builds require android/key.properties and a protected production keystore."
    }
    require(file("google-services.json").isFile) {
        "Release builds require android/app/google-services.json for Firebase push notifications."
    }
}

android {
    namespace = "com.starforge.starforge_student"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Matches the Android client registered in google-services.json.
        // Keep namespace/MainActivity stable; the application ID is the
        // Play/Firebase identity installed on devices.
        applicationId = "com.starforge.student"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // CI/prod supplies key.properties through protected secrets.
            // A release is never signed with the debug key.
            signingConfig = signingConfigs.findByName("release")
            // Keep protected release builds reliable on the 7 GiB GitHub and
            // local runners. Dart AOT still produces a release binary; only
            // Android bytecode/resource shrinking is disabled here.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
