import os, sys, shutil

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

# ── Copy logo to mipmap folders ─────────────────────────────
logo = 'assets/logo.png'
if os.path.exists(logo):
    try:
        from PIL import Image
    except ImportError:
        os.system('pip install Pillow --break-system-packages -q')
        from PIL import Image
    
    img = Image.open(logo).convert('RGBA')
    sizes = {
        'mipmap-mdpi': 48, 'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192,
    }
    for folder, size in sizes.items():
        d = f'android/app/src/main/res/{folder}'
        os.makedirs(d, exist_ok=True)
        r = img.resize((size, size), Image.LANCZOS)
        r.save(f'{d}/ic_launcher.png')
        r.save(f'{d}/ic_launcher_round.png')
        print(f"Logo {size}x{size} -> {folder}")
    print("Logo done!")
else:
    print("No assets/logo.png found")
