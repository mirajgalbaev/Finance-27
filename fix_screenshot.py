import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# We need to replace the current `capture` call:
#        final Uint8List? imageBytes = await _screenshotController.capture(
#          delay: const Duration(milliseconds: 500),
#        );

# with captureFromLongWidget, adding the ProviderScope and bounded width.
old_pattern = r"final Uint8List\? imageBytes = await _screenshotController\.capture\([\s\S]*?delay: const Duration\(milliseconds: 500\),\n\s*\);"

new_code = """final Uint8List? imageBytes = await _screenshotController.captureFromLongWidget(
        ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: Container(
            width: MediaQuery.of(context).size.width < 800 ? 800 : MediaQuery.of(context).size.width,
            child: contentWidget,
          ),
        ),
        context: context,
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 500),
      );"""

new_text = re.sub(old_pattern, new_code, text)

if new_text != text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Fixed capture method in analytics_screen.dart!")
else:
    print("Could not find capture block.")
