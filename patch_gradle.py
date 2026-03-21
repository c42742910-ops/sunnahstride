import os, re, shutil, subprocess

# ── Patch build.gradle ─────────────────────────────────────
gradle = 'android/app/build.gradle'
if os.path.exists(gradle):
    f = open(gradle).read()
    # minSdk
    f = re.sub(r'minSdk\s*=?\s*\d+', 'minSdk = 21', f)
    f = re.sub(r'minSdkVersion\s+\d+', 'minSdkVersion 21', f)
    # desugaring
    if 'coreLibraryDesugaringEnabled' not in f:
        f = f.replace(
            'compileOptions {',
            'compileOptions {\n        coreLibraryDesugaringEnabled true'
        )
    if 'desugar_jdk_libs' not in f:
        f = f.replace(
            'dependencies {',
            'dependencies {\n    coreLibrary("com.android.tools:desugar_jdk_libs:2.0.4")'
        )
    open(gradle, 'w').write(f)
    print("build.gradle patched")

# ── Set app name ───────────────────────────────────────────
strings_dir = 'android/app/src/main/res/values'
os.makedirs(strings_dir, exist_ok=True)
strings_path = f'{strings_dir}/strings.xml'
with open(strings_path, 'w') as sf:
    sf.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">HalalCalorie</string>
</resources>''')
print("App name set: HalalCalorie")

# ── Generate app icons from logo.png ──────────────────────
logo_src = 'assets/logo.png'
if not os.path.exists(logo_src):
    print("WARNING: logo.png not found")
else:
    # mipmap sizes
    sizes = {
        'mipmap-mdpi':    48,
        'mipmap-hdpi':    72,
        'mipmap-xhdpi':   96,
        'mipmap-xxhdpi':  144,
        'mipmap-xxxhdpi': 192,
    }
    res_dir = 'android/app/src/main/res'
    
    try:
        from PIL import Image
        img = Image.open(logo_src).convert('RGBA')
        for folder, size in sizes.items():
            out_dir = f'{res_dir}/{folder}'
            os.makedirs(out_dir, exist_ok=True)
            resized = img.resize((size, size), Image.LANCZOS)
            # Save as ic_launcher.png
            resized.save(f'{out_dir}/ic_launcher.png')
            # Save round version too
            resized.save(f'{out_dir}/ic_launcher_round.png')
            print(f"  {folder}: {size}x{size} ✓")
        print("All app icons generated!")
    except ImportError:
        # Fallback: use sips (macOS)
        for folder, size in sizes.items():
            out_dir = f'{res_dir}/{folder}'
            os.makedirs(out_dir, exist_ok=True)
            subprocess.run([
                'sips', '-z', str(size), str(size),
                logo_src, '--out', f'{out_dir}/ic_launcher.png'
            ], capture_output=True)
            shutil.copy(
                f'{out_dir}/ic_launcher.png',
                f'{out_dir}/ic_launcher_round.png'
            )
        print("Icons generated with sips")
