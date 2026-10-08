import os

loc_path = r"C:\Finance 27\lib\core\localization_provider.dart"
planner_path = r"C:\Finance 27\lib\ui\screens\planner_screen.dart"

with open(loc_path, "r", encoding="utf-8") as f:
    l = f.read()

new_keys_en = """
      'main_template_upper': 'MAIN TEMPLATE',
      'status_action_upper': 'STATUS (ACTION)',
"""
new_keys_tr = """
      'main_template_upper': 'ANA ŞABLON',
      'status_action_upper': 'DURUM (İŞLEM)',
"""
new_keys_ru = """
      'main_template_upper': 'ГЛАВНЫЙ ШАБЛОН',
      'status_action_upper': 'СТАТУС (ДЕЙСТВИЕ)',
"""
new_keys_kg = """
      'main_template_upper': 'НЕГИЗГИ ШАБЛОН',
      'status_action_upper': 'АБАЛ (ИШ-АРАКЕТ)',
"""

l = l.replace("'open_pending': 'OPEN (PENDING)',", "'open_pending': 'OPEN (PENDING)'," + new_keys_en)
l = l.replace("'open_pending': 'AÇIK (BEKLİYOR)',", "'open_pending': 'AÇIK (BEKLİYOR)'," + new_keys_tr)
l = l.replace("'open_pending': 'ОТКРЫТО (ОЖИДАЕТ)',", "'open_pending': 'ОТКРЫТО (ОЖИДАЕТ)'," + new_keys_ru)
l = l.replace("'open_pending': 'АЧЫК (КҮТҮҮДӨ)',", "'open_pending': 'АЧЫК (КҮТҮҮДӨ)'," + new_keys_kg)

with open(loc_path, "w", encoding="utf-8") as f:
    f.write(l)

with open(planner_path, "r", encoding="utf-8") as f:
    p = f.read()

p = p.replace("Text('ANA ŞABLON')", "Text(AppStrings.get(ref, 'main_template_upper') ?? 'ANA ŞABLON')")
p = p.replace("Text('DURUM (İŞLEM)')", "Text(AppStrings.get(ref, 'status_action_upper') ?? 'DURUM (İŞLEM)')")

with open(planner_path, "w", encoding="utf-8") as f:
    f.write(p)

print("Updated ANA ŞABLON and DURUM (İŞLEM)")
