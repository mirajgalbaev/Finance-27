import io

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

imports_to_add = "import 'package:flutter/foundation.dart';\nimport 'package:universal_html/html.dart' as html;\n"

if "package:universal_html/html.dart" not in text:
    text = imports_to_add + text
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Added missing imports!")
else:
    print("Imports already exist.")
