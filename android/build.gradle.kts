allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.plugins.withId("com.android.library") {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                var pkg: String? = null
                if (manifestFile.exists()) {
                    val xml = manifestFile.readText()
                    val match = Regex("""package\s*=\s*"([^"]+)"""").find(xml)
                    if (match != null) {
                        pkg = match.groupValues[1]
                    }
                }
                if (pkg == null || pkg.isBlank()) {
                    pkg = "com.portal.${project.name.replace('-', '_')}"
                }
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                setNamespace.invoke(android, pkg)
            } catch (_: Throwable) {
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
