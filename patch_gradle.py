import os, sys, subprocess

# ── Patch build.gradle ──────────────────────────────────────
path = 'android/app/build.gradle'
if not os.path.exists(path):
    print("ERROR: build.gradle not found")
    sys.exit(1)

f = open(path).read()
f = f.replace('flutter.minSdkVersion', '21')
if 'isCoreLibraryDesugaringEnabled' not in f:
    f = f.replace('compileOptions {',
        'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
if 'desugar_jdk_libs' not in f:
    f = f.replace('dependencies {',
        'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")', 1)
open(path, 'w').write(f)
print("build.gradle patched")
print("minSdk 21:", 'minSdk 21' in f or '21' in f)
print("desugar:", 'desugar_jdk_libs' in f)

# ── Copy logo using sips (macOS built-in) ───────────────────
logo = 'assets/logo.png'
if os.path.exists(logo):
    sizes = {
        'mipmap-mdpi': 48, 'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192,
    }
    for folder, size in sizes.items():
        d = f'android/app/src/main/res/{folder}'
        os.makedirs(d, exist_ok=True)
        for name in ['ic_launcher.png', 'ic_launcher_round.png']:
            out = f'{d}/{name}'
            result = subprocess.run(
                ['sips', '-z', str(size), str(size), logo, '--out', out],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                print(f"Logo {size}x{size} -> {folder}/{name}")
            else:
                # Fallback: just copy the file
                import shutil
                shutil.copy(logo, out)
                print(f"Copied (no resize) -> {folder}/{name}")
    print("Logo done!")
else:
    print("WARNING: assets/logo.png not found - skipping logo")
