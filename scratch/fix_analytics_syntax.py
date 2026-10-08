import re

with open('lib/ui/screens/analytics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace property initializer with getter
content = content.replace(
    "final List<String> _monthNames = [",
    "List<String> get _monthNames => ["
)

with open('lib/ui/screens/analytics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed _monthNames in analytics_screen.dart")
