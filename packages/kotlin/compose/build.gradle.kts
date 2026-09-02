plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    namespace = "dev.naturalspacing.compose"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
    }
}

kotlin {
    jvmToolchain(17)
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    api(project(":"))
    api("androidx.compose.ui:ui-text:1.11.3")

    testImplementation(kotlin("test-junit"))
    testImplementation("junit:junit:4.13.2")
}
