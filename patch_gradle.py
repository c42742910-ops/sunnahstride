import os, sys
path = 'android/app/build.gradle'
if not os.path.exists(path):
    print("ERROR: not found, listing android/app/:")
    print(os.listdir('android/app/') if os.path.exists('android/app/') else "android/app/ missing!")
    sys.exit(1)
f = open(path).read()
f = f.replace('minSdk flutter.minSdkVersion', 'minSdk 21')
f = f.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')
if 'isCoreLibraryDesugaringEnabled' not in f:
    f = f.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
if 'desugar_jdk_libs' not in f:
    f = f.replace('dependencies {', 'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")', 1)
open(path, 'w').write(f)
print("Patched! minSdk21:", 'minSdk 21' in f, "desugar:", 'desugar_jdk_libs' in f)
