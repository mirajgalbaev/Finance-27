import io
import re
import os

files_to_fix = [
    'lib/ui/screens/analytics_screen.dart',
    'lib/ui/screens/planner_screen.dart',
    'lib/ui/screens/dashboard_screen.dart',
    'lib/ui/screens/daily_trade_journal_screen.dart'
]

replacements = {
    r'Platform\.isAndroid': r'defaultTargetPlatform == TargetPlatform.android',
    r'Platform\.isIOS': r'defaultTargetPlatform == TargetPlatform.iOS',
    r'Platform\.isWindows': r'defaultTargetPlatform == TargetPlatform.windows',
    r'Platform\.isMacOS': r'defaultTargetPlatform == TargetPlatform.macOS',
    r'Platform\.isLinux': r'defaultTargetPlatform == TargetPlatform.linux'
}

for path in files_to_fix:
    if not os.path.exists(path): continue
    with io.open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    new_text = text
    for p, r in replacements.items():
        new_text = re.sub(p, r, new_text)
    
    if text != new_text:
        with io.open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f"Fixed {path}")
    else:
        print(f"No changes in {path}")

