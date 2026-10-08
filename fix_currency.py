import io
import re

def fix_file(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # We replace: ref.read(currencyProvider) == 'USD' ? '\$' : 'X';
    # with: '\$'
    pattern = r"ref\.(?:read|watch)\(currencyProvider\)\s*==\s*'USD'\s*\?\s*'\\\$'\s*:\s*'.*?'"
    
    new_text = re.sub(pattern, r"'\\$'", text)
    
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    
    print(f'Fixed {path}, changed: {text != new_text}')

fix_file('lib/ui/screens/planner_screen.dart')
fix_file('lib/ui/screens/daily_trade_journal_screen.dart')
