allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define a shared build directory outside the project root
val sharedBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(sharedBuildDir)

subprojects {
    // Each module gets its own subfolder inside shared build
    layout.buildDirectory.set(sharedBuildDir.dir(name))
}

// Configure Android-specific settings globally
plugins.withId("com.android.application") {
    extensions.configure<com.android.build.gradle.AppExtension>("android") {
        ndkVersion = "27.0.12077973"
        // Add global android configs here if needed
    }
}
plugins.withId("com.android.library") {
    extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
        ndkVersion = "27.0.12077973"
    }
}

// Define a clean task that removes the shared build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
