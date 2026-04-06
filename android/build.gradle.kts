allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    // Only redirect build dir when source and target share the same drive root.
    // This prevents Path.relativize() failures on Windows when plugins come from
    // a different drive (e.g. Pub cache on C: vs project on D:).
    val srcRoot = project.projectDir.toPath().root
    val dstRoot = newSubprojectBuildDir.asFile.toPath().root
    if (srcRoot == dstRoot) {
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
