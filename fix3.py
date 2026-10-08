import sys

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("replaceAll('\n', ' ')", "replaceAll('\\n', ' ')")

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
