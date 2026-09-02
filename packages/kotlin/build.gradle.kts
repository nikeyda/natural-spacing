plugins {
    kotlin("jvm") version "2.0.20"
    kotlin("android") version "2.0.20" apply false
    id("com.android.library") version "8.11.1" apply false
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
}

kotlin {
    jvmToolchain(17)
}

tasks.register<JavaExec>("conformance") {
    dependsOn(tasks.testClasses)
    classpath = sourceSets.test.get().runtimeClasspath
    mainClass = "dev.naturalspacing.core.ConformanceMainKt"
    args(rootProject.projectDir.resolve("../..").normalize().absolutePath)
}
