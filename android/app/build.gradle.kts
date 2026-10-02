import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
}

// Firebase (FCM, Crashlytics) is wired only once a flavor has its google-services.json
// (gitignored, see README). Without it Crashlytics' mapping upload would fail the build.
val hasFirebaseConfig = file("src").listFiles()?.any { File(it, "google-services.json").exists() } == true ||
    file("google-services.json").exists()
if (hasFirebaseConfig) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Release signing comes from android/key.properties (gitignored) or CI env vars.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(key: String, env: String): String? =
    keystoreProperties.getProperty(key) ?: System.getenv(env)

// Per-country values. Keep in sync with lib/country/*/ configs.
data class CountryFlavor(
    val appIdSuffix: String,
    val appName: String,
    val deepLinkHost: String,
)
val countries = mapOf(
    "usa" to CountryFlavor(".usa", "I Want USA", "iwantusa.app"),
    "india" to CountryFlavor(".india", "I Want India", "iwantindia.app"),
)

android {
    buildFeatures {
        resValues = true
    }

    namespace = "com.calecute.iwant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.calecute.iwant"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = System.getenv("MAPS_API_KEY_ANDROID") ?: ""
    }

    flavorDimensions += listOf("country", "env")
    productFlavors {
        countries.forEach { (name, c) ->
            create(name) {
                dimension = "country"
                applicationIdSuffix = c.appIdSuffix
                manifestPlaceholders["deepLinkHost"] = c.deepLinkHost
                resValue("string", "app_name_base", c.appName)
            }
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabelSuffix"] = " Dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
            manifestPlaceholders["appLabelSuffix"] = " Beta"
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appLabelSuffix"] = ""
        }
    }

    signingConfigs {
        create("release") {
            val storePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val release = signingConfigs.getByName("release")
            // Fall back to debug keys so local release builds still run without a keystore.
            signingConfig = if (release.storeFile != null) release else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// Firebase config files live per flavor (android/app/src/<country><Env>/google-services.json)
// and are gitignored; builds without them still work with Firebase disabled at runtime.
if (hasFirebaseConfig) {
    configure<com.google.gms.googleservices.GoogleServicesPlugin.GoogleServicesPluginConfig> {
        missingGoogleServicesStrategy = com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.WARN
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
