import io
import os

files_to_check = [
    'lib/ui/screens/analytics_screen.dart',
    'lib/ui/screens/planner_screen.dart',
    'lib/ui/screens/dashboard_screen.dart',
    'lib/ui/screens/daily_trade_journal_screen.dart'
]

import_statement = "import 'package:flutter/foundation.dart';\n"

for path in files_to_check:
    if not os.path.exists(path): continue
    with io.open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    if "package:flutter/foundation.dart" not in text:
        # Prepend to the file
        new_text = import_statement + text
        with io.open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f"Added foundation import to {path}")
    else:
        print(f"Import already exists in {path}")

