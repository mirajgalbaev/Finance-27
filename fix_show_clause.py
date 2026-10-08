import io
import os
import re

files_to_check = [
    'lib/ui/screens/analytics_screen.dart',
    'lib/ui/screens/planner_screen.dart',
    'lib/ui/screens/dashboard_screen.dart',
    'lib/ui/screens/daily_trade_journal_screen.dart'
]

for path in files_to_check:
    if not os.path.exists(path): continue
    with io.open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    new_text = re.sub(r"import 'package:flutter/foundation.dart' show kIsWeb;", r"import 'package:flutter/foundation.dart';", text)
    
    if text != new_text:
        with io.open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f"Fixed show clause in {path}")
    else:
        print(f"No show clause found in {path}")

