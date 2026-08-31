"""Generate all platform-specific icon sizes from the master 512x512 PNG."""
import os
from PIL import Image

SRC = "assets/axismind_icon.png"
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def resize(src_path, size):
    img = Image.open(src_path).resize((size, size), Image.LANCZOS)
    return img

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  -> {path} ({img.size[0]}x{img.size[1]})")

print("=== Android mipmap icons ===")
android_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in android_sizes.items():
    path = os.path.join(BASE, "android", "app", "src", "main", "res", folder, "ic_launcher.png")
    img = resize(SRC, size)
    save(img, path)

print("\n=== Web icons ===")
web_sizes = {
    "favicon.png": 48,
    "icons/Icon-192.png": 192,
    "icons/Icon-512.png": 512,
    "icons/Icon-maskable-192.png": 192,
    "icons/Icon-maskable-512.png": 512,
}
for rel, size in web_sizes.items():
    path = os.path.join(BASE, "web", rel)
    img = resize(SRC, size)
    save(img, path)

print("\n=== iOS icons ===")
ios_sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
ios_dir = os.path.join(BASE, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
for name, size in ios_sizes.items():
    path = os.path.join(ios_dir, name)
    img = resize(SRC, size)
    save(img, path)

print("\n=== macOS icons ===")
mac_sizes = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}
mac_dir = os.path.join(BASE, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
for name, size in mac_sizes.items():
    path = os.path.join(mac_dir, name)
    img = resize(SRC, size)
    save(img, path)

print("\n=== Windows icon ===")
ico_path = os.path.join(BASE, "windows", "runner", "resources", "app_icon.ico")
img = Image.open(SRC)
img.save(ico_path, format="ICO", sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
print(f"  -> {ico_path} (multi-size ICO)")

print("\n[OK] All icons applied successfully!")
