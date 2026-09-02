plugins {
    id("com.android.application")
    kotlin("android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "dev.naturalspacing.acceptance.android"
    compileSdk = 35

    defaultConfig {
        applicationId = "dev.naturalspacing.acceptance.android"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "0.0.0-local"
    }

    lint {
        // This host intentionally matches the library's API 35 compatibility matrix.
        disable += setOf("GradleDependency", "OldTargetApi")
    }

    buildFeatures {
        compose = true
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("androidx.activity:activity:1.9.0")
    implementation("androidx.compose.foundation:foundation:1.11.3")
    implementation("androidx.compose.ui:ui:1.11.3")
    implementation("consumer.local:natural-spacing-android:0")
    implementation("consumer.local:natural-spacing-compose:0")
}
