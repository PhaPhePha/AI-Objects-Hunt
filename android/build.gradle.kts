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
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")

    // Force all Kotlin modules, including tflite_flutter, to use JVM 17
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val addDependencies = Action<Project> {
        dependencies {
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
            add("implementation", "androidx.concurrent:concurrent-futures-ktx:1.2.0")
        }
    }

    if (state.executed) {
        addDependencies.execute(this)
    } else {
        afterEvaluate(addDependencies)
    }
}