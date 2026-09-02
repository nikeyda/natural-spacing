pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "natural-spacing-kotlin"

include(":compose")
include(":android-views")
project(":android-views").projectDir = file("android")
