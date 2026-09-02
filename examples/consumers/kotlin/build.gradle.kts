plugins {
    id("com.android.library") version "8.11.1" apply false
    kotlin("jvm") version "2.0.20"
    kotlin("android") version "2.0.20" apply false
    application
}

dependencies {
    implementation("consumer.local:natural-spacing-core:0")
}

kotlin {
    jvmToolchain(17)
}

application {
    mainClass = "NaturalSpacingConsumerKt"
}
