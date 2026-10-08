import re

with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix const Expanded in _showEditTaskDialog
content = content.replace(
    "const Expanded(child: Text(AppStrings.get(ref, 'edit_task')",
    "Expanded(child: Text(AppStrings.get(ref, 'edit_task')"
)

# Fix const Padding for todays_tasks
# Line 417-419:
# const Padding(
#   padding: EdgeInsets.symmetric(vertical: 8.0),
#   child: Text(AppStrings.get(ref, 'todays_tasks') ?? 'BUGÜNÜN GÖREVLERİ', style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
# ),
content = content.replace(
    "const Padding(\n                              padding: EdgeInsets.symmetric(vertical: 8.0),\n                              child: Text(AppStrings.get(ref, 'todays_tasks')",
    "Padding(\n                              padding: const EdgeInsets.symmetric(vertical: 8.0),\n                              child: Text(AppStrings.get(ref, 'todays_tasks')"
)
# Just in case whitespace is different:
content = re.sub(
    r"const Padding\(\s*padding: EdgeInsets\.symmetric\(vertical: 8\.0\),\s*child: Text\(AppStrings\.get\(ref, 'todays_tasks'\)",
    r"Padding(\n                              padding: const EdgeInsets.symmetric(vertical: 8.0),\n                              child: Text(AppStrings.get(ref, 'todays_tasks')",
    content
)

with open('lib/ui/screens/planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed remaining const errors.")
