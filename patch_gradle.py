
import os, sys

path = 'android/app/build.gradle'
if not os.path.exists(path):
    sys.exit(1)

f = open(path).read()
print("=== build.gradle preview ===")
print(f[:800])
print("=== end preview ===")

# Replace minSdk
f = f.replace('flutter.minSdkVersion', '21')

# Add desugaring - append to android block
if 'isCoreLibraryDesugaringEnabled' not in f:
    # Add after compileOptions opening or create it
    if 'compileOptions' in f:
        f = re.sub(r'compileOptions \{([^}]*)}',
            lambda m: 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true' + m.group(1) + '}', f)
    else:
        f = f.replace('buildTypes {', 'compileOptions {\n        sourceCompatibility JavaVersion.VERSION_1_8\n        targetCompatibility JavaVersion.VERSION_1_8\n        isCoreLibraryDesugaringEnabled = true\n    }\n    buildTypes {')

# Add desugar dependency
if 'desugar_jdk_libs' not in f:
    f = f.replace('\ndependencies {', '\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"')

open(path, 'w').write(f)
print("minSdk 21:", "minSdkVersion 21" in f or "minSdk 21" in f)
print("desugar:", "desugar_jdk_libs" in f)
print("isCoreLibrary:", "isCoreLibraryDesugaringEnabled" in f)
