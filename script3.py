import re

with open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"const Expanded\(child: Center\(child: Text\('.*?bulunamad.*?', style: TextStyle\(color: Colors.white54, fontSize: 32\)\)\)\)", r"Expanded(child: Center(child: Text(AppStrings.get(ref, 'no_tasks_found') ?? 'Seçilen dönem için görev bulunamadı.', style: const TextStyle(color: Colors.white54, fontSize: 32))))", content)

content = re.sub(r"Text\('.*?bulunamad.*?', style: TextStyle\(color: Colors\.white54\)\)", r"Text(AppStrings.get(ref, 'no_tasks_found') ?? 'Seçilen dönem için görev bulunamadı.', style: const TextStyle(color: Colors.white54))", content)

with open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done")
