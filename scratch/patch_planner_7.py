planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

# Remove 'const SnackBar' when it contains AppStrings
import re
p_content = re.sub(r'const SnackBar\(\s*content:\s*Text\(AppStrings\.get', r'SnackBar(content: Text(AppStrings.get', p_content)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
