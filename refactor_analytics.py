import os
import re

file_path = 'lib/ui/screens/analytics_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Change _exportScreenshot signature
content = content.replace("Future<void> _exportScreenshot() async {", "Future<void> _exportScreenshot(Widget exportContentWidget) async {")

# 2. Change onTap: _exportScreenshot to onTap: () => _exportScreenshot(exportContentWidget)
# We need to find the InkWell that calls _exportScreenshot
content = content.replace("onTap: _exportScreenshot,", "onTap: () => _exportScreenshot(exportContentWidget),")

# 3. Inside build(), wrap the Container in a closure
# Let's find: `child: Screenshot(`
# And change it so we define `final exportContentWidget = Container(...);` before `return Scaffold(`

# Let's find `return Scaffold(` and insert the closure before it.
# Actually, the Container is huge. It's better to just pass it inline if possible? No, it's inside Scaffold.
# Let's extract everything from `child: Screenshot(` down to its closing.

import collections

def find_matching_brace(text, start_index, open_brace='(', close_brace=')'):
    count = 0
    for i in range(start_index, len(text)):
        if text[i] == open_brace:
            count += 1
        elif text[i] == close_brace:
            count -= 1
            if count == 0:
                return i
    return -1

screenshot_idx = content.find('child: Screenshot(')
if screenshot_idx != -1:
    container_idx = content.find('child: Container(', screenshot_idx)
    end_container_idx = find_matching_brace(content, container_idx + 15, '(', ')')
    
    container_code = content[container_idx + 7 : end_container_idx + 1]
    
    # Define it before return Scaffold(
    scaffold_idx = content.find('return Scaffold(')
    
    new_code = "final exportContentWidget = " + container_code + ";\n    "
    content = content[:scaffold_idx] + new_code + content[scaffold_idx:]
    
    # Now replace the child: Screenshot(...) with child: exportContentWidget,
    # Need to find the end of Screenshot(
    end_screenshot_idx = find_matching_brace(content, screenshot_idx + 17, '(', ')')
    
    content = content[:screenshot_idx] + "child: exportContentWidget" + content[end_screenshot_idx + 1:]

# 4. In _exportScreenshot, replace capture() with captureFromLongWidget()
capture_pattern = r"final Uint8List\? imageBytes = await _screenshotController\.capture\([\s\S]*?\);"
replacement = """final Uint8List? imageBytes = await _screenshotController.captureFromLongWidget(
      ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: exportContentWidget,
      ),
      context: context,
      pixelRatio: 2.0,
      delay: const Duration(milliseconds: 500),
    );"""

content = re.sub(capture_pattern, replacement, content)

# 5. Fix the success SnackBar and Gal integration
content = content.replace("await file.writeAsBytes(imageBytes);", "await Gal.putImage(filePath);")

# Update success messages
snack_png = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\('Kay[^\n]*?PNG[^\n]*?'\),[\s\S]*?backgroundColor: Colors\.green,[\s\S]*?\),[\s\S]*?\);"
snack_png_replacement = """ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png').replaceAll('{path}', filePath)), backgroundColor: Colors.green));"""

snack_pdf = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\('Kay[^\n]*?PDF[^\n]*?'\),[\s\S]*?backgroundColor: Colors\.green,[\s\S]*?\),[\s\S]*?\);"
snack_pdf_replacement = """ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_pdf').replaceAll('{path}', filePath)), backgroundColor: Colors.green));"""

content = re.sub(snack_png, snack_png_replacement, content)
content = re.sub(snack_pdf, snack_pdf_replacement, content)

# Add ProviderScope import if missing
if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in content:
    content = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + content

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Analytics refactored")
