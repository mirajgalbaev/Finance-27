planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "decoration: const InputDecoration(hintText: (AppStrings.get(ref, 'enter_new_title') ?? 'Yeni başlık girin...')),",
    "decoration: InputDecoration(hintText: (AppStrings.get(ref, 'enter_new_title') ?? 'Yeni başlık girin...')),"
)
p_content = p_content.replace(
    "decoration: const InputDecoration(labelText: 'Yeni Ana Başlık'),",
    "decoration: InputDecoration(labelText: AppStrings.get(ref, 'new_main_title') ?? 'Yeni Ana Başlık'),"
)
p_content = p_content.replace(
    "decoration: const InputDecoration(labelText: 'Görev Adı'),",
    "decoration: InputDecoration(labelText: AppStrings.get(ref, 'task_name') ?? 'Görev Adı'),"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
