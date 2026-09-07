group = "com.personaclick.personaclick_flutter_sdk"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
        maven(url = "https://jitpack.io")
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://jitpack.io")
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.personaclick.personaclick_flutter_sdk"

    compileSdk = 36

    flavorDimensions += "brand"

    productFlavors {
        create("personaclick") {
            dimension = "brand"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        // The PersonaClick Android library is flavored on a `default` dimension
        // (personaclick / personaclick); this plugin has no such dimension. Tell Gradle
        // which flavor to consume. A no-op for the single-variant JitPack artifact;
        // required when the SDK is consumed from source (local `includeBuild`).
        missingDimensionStrategy("default", "personaclick")
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    // PersonaClick Android SDK.
    val personaclickAndroidSdkVersion = "v2.38.0"
    add("personaclickImplementation", "com.github.personaclick:android-sdk:$personaclickAndroidSdkVersion")

    // Used directly by the push presenter (NotificationCompat / ContextCompat). The native SDK
    // depends on the same version but as `implementation`, so it is not exposed transitively.
    implementation("androidx.core:core-ktx:1.13.1")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
