// Top-level build.gradle.kts file

plugins {
    id("com.android.application") version "8.7.3" apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false // ✅ Match this version
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Custom build directory location
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
