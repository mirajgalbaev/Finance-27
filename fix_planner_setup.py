import os

loc_path = r"C:\Finance 27\lib\core\localization_provider.dart"
planner_path = r"C:\Finance 27\lib\ui\screens\planner_screen.dart"

with open(loc_path, "r", encoding="utf-8") as f:
    l = f.read()

# Add to EN
l = l.replace("'add_task': 'Add Task',", "'add_task': 'Add Task',\n      'add_new_task': 'Add New Task',")

# Add to TR
l = l.replace("'add_task': 'Görev Ekle',", "'add_task': 'Görev Ekle',\n      'add_new_task': 'Yeni Görev Ekle',")

# Add to RU
l = l.replace("'add_task': 'Добавить задачу',", "'add_task': 'Добавить задачу',\n      'add_new_task': 'Добавить новую задачу',")

# Add to KG
l = l.replace("'add_task': 'Тапшырма кошуу',", "'add_task': 'Тапшырма кошуу',\n      'add_new_task': 'Жаңы тапшырма кошуу',")

with open(loc_path, "w", encoding="utf-8") as f:
    f.write(l)

with open(planner_path, "r", encoding="utf-8") as f:
    p = f.read()

p = p.replace("Text('PLANNER SETUP'", "Text((AppStrings.get(ref, 'planner_setup') ?? 'Planner Setup').toUpperCase()")
p = p.replace("Text('Yeni Görev Ekle'", "Text(AppStrings.get(ref, 'add_new_task') ?? 'Yeni Görev Ekle'")

with open(planner_path, "w", encoding="utf-8") as f:
    f.write(p)

print("Updated planner setup and add new task")
