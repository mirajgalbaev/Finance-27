import re
import os

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

# Add keys to localization_provider
additions = {
    'en': {
        'home_page': 'Home Page',
        'completed_tasks': 'COMPLETED TASKS',
        'active_fin_goals': 'Financial Goals',
        'prog_goal_label': 'Progress Goals (e.g. Learning a Language)'
    },
    'tr': {
        'home_page': 'Ana Sayfa',
        'completed_tasks': 'TAMAMLANAN GÖREVLER',
        'active_fin_goals': 'Finansal Hedefler',
        'prog_goal_label': 'İlerleme Hedefleri (Kişisel Gelişim)'
    },
    'ru': {
        'home_page': 'Главная',
        'completed_tasks': 'ЗАВЕРШЕННЫЕ ЗАДАЧИ',
        'active_fin_goals': 'Финансовые цели',
        'prog_goal_label': 'Цели прогресса (например, изучение языка)'
    },
    'kg': {
        'home_page': 'Башкы бет',
        'completed_tasks': 'АТКАРЫЛГАН ТАПШЫРМАЛАР',
        'active_fin_goals': 'Финансылык максаттар',
        'prog_goal_label': 'Прогресс максаттары (мис. Тил үйрөнүү)'
    }
}

with open(loc_file, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
current_lang = None

for line in lines:
    lang_match = re.match(r"^\s*'([a-z]{2})':\s*\{\s*$", line)
    if lang_match:
        current_lang = lang_match.group(1)
        new_lines.append(line)
        if current_lang in additions:
            for k, v in additions[current_lang].items():
                new_lines.append(f"      '{k}': '{v}',")
        continue
    if current_lang is not None and line.strip() == '},':
        current_lang = None
    new_lines.append(line)

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))


# Patch planner_screen.dart
planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "String _selectedMainTab = 'Ana Sayfa';",
    "int _selectedMainTabIndex = 0;"
)
p_content = p_content.replace(
    "Widget _buildMainTabButton(String title) {",
    "Widget _buildMainTabButton(int index, String title) {"
)
p_content = p_content.replace(
    "bool isSelected = _selectedMainTab == title;",
    "bool isSelected = _selectedMainTabIndex == index;"
)
p_content = p_content.replace(
    "onTap: () => setState(() => _selectedMainTab = title),",
    "onTap: () => setState(() => _selectedMainTabIndex = index),"
)
p_content = p_content.replace(
    "_buildMainTabButton('Ana Sayfa'),",
    "_buildMainTabButton(0, AppStrings.get(ref, 'home_page') ?? 'Ana Sayfa'),"
)
p_content = p_content.replace(
    "_buildMainTabButton('Günlük Plan'),",
    "_buildMainTabButton(1, AppStrings.get(ref, 'daily_plan') ?? 'Günlük Plan'),"
)
p_content = p_content.replace(
    "_buildMainTabButton('Açık İşlemler'),",
    "_buildMainTabButton(2, AppStrings.get(ref, 'open_trades') ?? 'Açık İşlemler'),"
)
p_content = p_content.replace(
    "_selectedMainTab == 'Ana Sayfa'",
    "_selectedMainTabIndex == 0"
)
p_content = p_content.replace(
    "_selectedMainTab == 'Günlük Plan'",
    "_selectedMainTabIndex == 1"
)
p_content = p_content.replace(
    "Text('TAMAMLANAN GÖREVLER (${completedReminders.length})'",
    "Text('${AppStrings.get(ref, 'completed_tasks') ?? 'TAMAMLANAN GÖREVLER'} (${completedReminders.length})'"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)


# Patch dashboard_screen.dart
dashboard = r'C:\Finance 27\lib\ui\screens\dashboard_screen.dart'
with open(dashboard, 'r', encoding='utf-8') as f:
    d_content = f.read()

d_content = d_content.replace(
    "const Text('Finansal Hedefler',",
    "Text(AppStrings.get(ref, 'active_fin_goals') ?? 'Finansal Hedefler',"
)
d_content = d_content.replace(
    "const Text('İlerleme Hedefleri (Kişisel Gelişim)',",
    "Text(AppStrings.get(ref, 'prog_goal_label') ?? 'İlerleme Hedefleri (Kişisel Gelişim)',"
)

with open(dashboard, 'w', encoding='utf-8') as f:
    f.write(d_content)

print("Patched planner and dashboard.")
