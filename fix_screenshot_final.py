import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Pattern to match the whole captureFromLongWidget block
pattern = r"final Uint8List\? imageBytes = await _screenshotController\.captureFromLongWidget\([\s\S]*?delay: const Duration\(milliseconds: 500\),\n\s*\);"

replacement = """final Uint8List? imageBytes = await _screenshotController.capture(
          delay: const Duration(milliseconds: 500),
        );"""

new_text = re.sub(pattern, replacement, text)

if text != new_text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Reverted to capture() in analytics_screen.dart!")
else:
    print("Could not match the pattern.")
