import io
import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r"sortedTrades\.sort\(\(a, b\)\s*\{\s*bool aClosed.*?return b\.date\.compareTo\(a\.date\);\s*\}\);"
new_text = re.sub(pattern, "sortedTrades.sort((a, b) => b.date.compareTo(a.date));", text, flags=re.DOTALL)

if new_text != text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Fixed daily_trade_journal_screen.dart sort logic!")
else:
    print("No matches in daily_trade_journal_screen.dart")
