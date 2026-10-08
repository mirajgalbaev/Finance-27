import re

path = 'lib/ui/screens/planner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace all occurrences of _buildTabButton('Spot'), with _buildTabButton('Spot'), SizedBox, _buildTabButton('MT5')
old_tabs = "_buildTabButton('Spot'),"
new_tabs = "_buildTabButton('Spot'),\n                  const SizedBox(width: 4),\n                  _buildTabButton('MT5'),"

content = content.replace(old_tabs, new_tabs)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Added MT5 tab button in planner_screen")
