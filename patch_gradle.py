import os, sys

path = 'android/app/build.gradle'
if not os.path.exists(path):
    print(f"ERROR: {path} not found")
    print("CWD:", os.getcwd())
    print("Contents:", os.listdir('.'))
    sys.exit(1)

f = open(path).read()
print("Original build.gradle loaded, size:", len(f))

f = f.replace('minSdk flutter.minSdkVersion', 'minSdk 21')
f = f.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')

if 'isCoreLibraryDesugaringEnabled' not in f:
    f = f.replace('compileOptions {',
        'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')

if 'desugar_jdk_libs' not in f:
    f = f.replace('dependencies {',
        'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")', 1)

open(path, 'w').write(f)
print("Patched successfully!")
print("minSdk 21:", 'minSdk 21' in f)
print("desugaring:", 'isCoreLibraryDesugaringEnabled' in f)
print("desugar_jdk_libs:", 'desugar_jdk_libs' in f)
