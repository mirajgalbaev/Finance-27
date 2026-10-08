import io
import re

path = 'pubspec.yaml'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add flutter_native_splash to dev_dependencies if not there
if "flutter_native_splash:" not in text:
    text = re.sub(
        r"(dev_dependencies:)",
        r"dev_dependencies:\n  flutter_native_splash: ^2.4.0",
        text
    )

config = """

flutter_native_splash:
  color: "#0F172A"
  image: "assets/splash_icon.png"
  android_12:
    image: "assets/splash_icon.png"
    icon_background_color: "#0F172A"
    color: "#0F172A"
  web: false
"""

if "flutter_native_splash:\n  color" not in text:
    text += config

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated pubspec.yaml for splash screen")
