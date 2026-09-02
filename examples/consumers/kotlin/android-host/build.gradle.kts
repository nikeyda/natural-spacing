plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    namespace = "consumer.naturalspacing.android"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("consumer.local:natural-spacing-android:0")
    implementation("consumer.local:natural-spacing-compose:0")
}
