import os

file_path = 'lib/ui/screens/analytics_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace onTap: () => _exportScreenshot(exportContentWidget), with onTap: () => _exportScreenshot(buildExportContent()),
content = content.replace("onTap: () => _exportScreenshot(exportContentWidget),", "onTap: () => _exportScreenshot(buildExportContent()),")

# Now find child: Screenshot( and extract its Container to buildExportContent
screenshot_idx = content.find('child: Screenshot(')
container_idx = content.find('child: Container(', screenshot_idx)

# Find the end of this Container
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

end_container_idx = find_matching_brace(content, container_idx + 15, '(', ')')

container_code = content[container_idx + 7 : end_container_idx + 1]

# Insert Widget buildExportContent() { return ...; } before return Scaffold(
scaffold_idx = content.find('return Scaffold(')
closure_code = f"Widget buildExportContent() {{\n      return {container_code};\n    }}\n\n    "

# Replace the child of Screenshot with buildExportContent()
# wait, the original child of Screenshot was child: Container( ... ).
# we replace that exact string with child: buildExportContent()
content = content[:container_idx] + "child: buildExportContent()" + content[end_container_idx + 1:]

# We must adjust scaffold_idx because the string length changed
scaffold_idx = content.find('return Scaffold(')
content = content[:scaffold_idx] + closure_code + content[scaffold_idx:]

# In _exportScreenshot, replace exportContentWidget with buildExportContentWidget (actually it expects a Widget)
content = content.replace("Future<void> _exportScreenshot(Widget exportContentWidget) async {", "Future<void> _exportScreenshot(Widget contentWidget) async {")
content = content.replace("child: exportContentWidget,", "child: contentWidget,")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
