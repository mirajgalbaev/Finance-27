import re

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"_buildStatItem\(\(AppStrings\.get\(ref,\s*'total_task'\)\s*\?\?\s*'Toplam G[^']*rev'\)\.replaceAll\('\n',\s*' '\),\s*total\.toString\(\),\s*Colors\.blueAccent\)",
    "_buildStatItem((AppStrings.get(ref, 'total_task') ?? 'Toplam Görev').replaceAll('\\n', ' '), total.toString(), Colors.blueAccent)",
    content
)

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
