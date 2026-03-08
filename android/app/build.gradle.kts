import java.util.Properties
import java.io.FileInputStream


plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
val keystorePropertiesFile: File = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "de.lemarq.stimmapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    defaultConfig {
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = false
            // This line tells the build to use your new rules file.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            // This line tells the build to use your new rules file.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    flavorDimensions += "app"

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "de.lemarq.stimmapp.dev"
            manifestPlaceholders["deepLinkHost"] = "stimmapp-dev.web.app"
            manifestPlaceholders["debugDeepLinkHost"] = "stimmapp-dev.web.app"
            // Use official AdMob test app id for development builds.
            manifestPlaceholders["adMobAppId"] =
                "ca-app-pub-3940256099942544~3347511713"
            resValue("string", "app_name", "StimmApp Dev")
        }
        create("prod") {
            dimension = "app"
            applicationId = "de.lemarq.stimmapp"
            manifestPlaceholders["deepLinkHost"] = "stimmapp.net"
            manifestPlaceholders["debugDeepLinkHost"] = "stimmapp.net"
            manifestPlaceholders["adMobAppId"] =
                "ca-app-pub-5296065079333841~8760518694"
            resValue("string", "app_name", "StimmApp")
        }
    }

    // Orchestrator disabled to simplify debugging
    // testOptions {
    //     execution = "ANDROIDX_TEST_ORCHESTRATOR"
    // }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-ads:23.0.0")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.fragment:fragment-ktx:1.6.2")
    // androidTestUtil("androidx.test:orchestrator:1.4.2") // Disabled
}
