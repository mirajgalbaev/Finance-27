import io
import re

path = 'pubspec.yaml'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add to dev_dependencies
text = re.sub(
    r"(dev_dependencies:)",
    r"dev_dependencies:\n  flutter_launcher_icons: ^0.13.1",
    text
)

config = """

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/app_icon.jpg"
  web:
    generate: true
    image_path: "assets/app_icon.jpg"
    background_color: "#0F172A"
    theme_color: "#0F172A"
  windows:
    generate: true
    image_path: "assets/app_icon.jpg"
    icon_size: 256
"""

text += config

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated pubspec.yaml")
