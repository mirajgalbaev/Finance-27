import re

with open('lib/ui/screens/goals_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace const SnackBar( with SnackBar(
content = content.replace(
    "const SnackBar(\n                          content: Text(AppStrings.get(ref, 'goal_not_approved')",
    "SnackBar(\n                          content: Text(AppStrings.get(ref, 'goal_not_approved')"
)
# Wait, why was ref undefined? Let's check where _showEditGoalDialog is defined
# void _showEditGoalDialog(BuildContext context, WidgetRef ref, GoalModel goal)
# Ah, the problem is _showAddGoalDialog!
# Does _showAddGoalDialog take ref?
# void _showAddGoalDialog(BuildContext context) { ... }
# If it doesn't take ref, I must pass ref to it.

content = content.replace(
    "void _showAddGoalDialog(BuildContext context) {",
    "void _showAddGoalDialog(BuildContext context, WidgetRef ref) {"
)
content = content.replace(
    "_showAddGoalDialog(context);",
    "_showAddGoalDialog(context, ref);"
)
content = content.replace(
    "const SnackBar(",
    "SnackBar("
)

with open('lib/ui/screens/goals_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed goals_screen.dart")
