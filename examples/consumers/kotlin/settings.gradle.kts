pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "natural-spacing-consumer"
include(":android-host")

includeBuild("../../../packages/kotlin") {
    dependencySubstitution {
        substitute(module("consumer.local:natural-spacing-core"))
            .using(project(":"))
        substitute(module("consumer.local:natural-spacing-android"))
            .using(project(":android-views"))
        substitute(module("consumer.local:natural-spacing-compose"))
            .using(project(":compose"))
    }
}
