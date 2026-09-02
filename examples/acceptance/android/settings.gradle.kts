pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "natural-spacing-android-acceptance"
include(":app")

includeBuild("../../../packages/kotlin") {
    dependencySubstitution {
        substitute(module("consumer.local:natural-spacing-android"))
            .using(project(":android-views"))
        substitute(module("consumer.local:natural-spacing-compose"))
            .using(project(":compose"))
    }
}
