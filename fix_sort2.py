import io
import re

path = 'lib/ui/screens/planner_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix the complex sort
pattern1 = r"displayedTrades\.sort\(\(a, b\)\s*\{\s*if\s*\(a\.exitPrice\s*==\s*null\s*&&\s*b\.exitPrice\s*!=\s*null\)\s*return\s*-1;\s*if\s*\(a\.exitPrice\s*!=\s*null\s*&&\s*b\.exitPrice\s*==\s*null\)\s*return\s*1;\s*return\s*b\.date\.compareTo\(a\.date\);\s*\}\);"
new_text = re.sub(pattern1, "displayedTrades.sort((a, b) => b.date.compareTo(a.date));", text, flags=re.DOTALL)

# 2. Add sorting to monthTrades.where(...)
pattern2 = r"final displayedTrades = monthTrades\.where\(\(t\) => t\.market == _selectedTab\)\.toList\(\);"
replacement2 = r"final displayedTrades = monthTrades.where((t) => t.market == _selectedTab).toList();\n    displayedTrades.sort((a, b) => b.date.compareTo(a.date));"
new_text = new_text.replace("final displayedTrades = monthTrades.where((t) => t.market == _selectedTab).toList();", replacement2)

if new_text != text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Fixed planner_screen.dart sort logic!")
else:
    print("No matches in planner_screen.dart")
