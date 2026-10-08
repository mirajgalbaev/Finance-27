import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("                  ], // close else block", "")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
