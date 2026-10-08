import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# The error is at line 642: "      ),"
# Let's verify and remove it.
if ")," in lines[641]:
    del lines[641]
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("Removed line 642")
else:
    print("Line 642 does not contain '),'. It contains:", lines[641].strip())
