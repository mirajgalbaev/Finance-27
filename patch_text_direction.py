import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import 'dart:ui' as ui; if it's not there
if "import 'dart:ui' as ui;" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:ui' as ui;")

# Replace TextDirection.ltr with ui.TextDirection.ltr
content = content.replace("textDirection: TextDirection.ltr,", "textDirection: ui.TextDirection.ltr,")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Fixed TextDirection conflict")
