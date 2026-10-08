import os

loc_path = r"C:\Finance 27\lib\core\localization_provider.dart"
planner_path = r"C:\Finance 27\lib\ui\screens\planner_screen.dart"

# Update localization_provider.dart
with open(loc_path, "r", encoding="utf-8") as f:
    l = f.read()

new_keys_en = """
      'export_plan_format': 'In what format do you want to save this plan?',
"""
new_keys_tr = """
      'export_plan_format': 'Bu planı hangi formatta kaydetmek istiyorsunuz?',
"""
new_keys_ru = """
      'export_plan_format': 'В каком формате вы хотите сохранить этот план?',
"""
new_keys_kg = """
      'export_plan_format': 'Бул планды кайсы форматта сактагыңыз келет?',
"""

l = l.replace("'export_daily_plan_format': 'In what format do you want to save your daily plan?',", "'export_daily_plan_format': 'In what format do you want to save your daily plan?'," + new_keys_en)
l = l.replace("'export_daily_plan_format': 'Günlük planınızı hangi formatta kaydetmek istiyorsunuz?',", "'export_daily_plan_format': 'Günlük planınızı hangi formatta kaydetmek istiyorsunuz?'," + new_keys_tr)
l = l.replace("'export_daily_plan_format': 'В каком формате вы хотите сохранить ежедневный план?',", "'export_daily_plan_format': 'В каком формате вы хотите сохранить ежедневный план?'," + new_keys_ru)
l = l.replace("'export_daily_plan_format': 'Күнүмдүк планды кайсы форматта сактагыңыз келет?',", "'export_daily_plan_format': 'Күнүмдүк планды кайсы форматта сактагыңыз келет?'," + new_keys_kg)

with open(loc_path, "w", encoding="utf-8") as f:
    f.write(l)

# Update planner_screen.dart
with open(planner_path, "r", encoding="utf-8") as f:
    p = f.read()

p = p.replace("Text('Bu planı hangi formatta kaydetmek istiyorsunuz?'", "Text(AppStrings.get(ref, 'export_plan_format') ?? 'Bu planı hangi formatta kaydetmek istiyorsunuz?'")

with open(planner_path, "w", encoding="utf-8") as f:
    f.write(p)

print("Updated export_plan_format")
