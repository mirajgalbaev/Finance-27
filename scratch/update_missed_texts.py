import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'no_jar_balance': 'No balance in jars.',
        'total_tasks': 'Total: {total} Tasks',
        'total_goals': 'Total: {total} Goals',
    },
    'tr': {
        'no_jar_balance': 'Kavanozlarda bakiye bulunmuyor.',
        'total_tasks': 'Toplam: {total} Görev',
        'total_goals': 'Toplam: {total} Hedef',
    },
    'ru': {
        'no_jar_balance': 'В кувшинах нет средств.',
        'total_tasks': 'Всего: {total} Задач',
        'total_goals': 'Всего: {total} Целей',
    },
    'kg': {
        'no_jar_balance': 'Кумураларда каражат жок.',
        'total_tasks': 'Жалпы: {total} Тапшырма',
        'total_goals': 'Жалпы: {total} Максат',
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


# Update analytics_screen.dart
analytics_file = r'C:\Finance 27\lib\ui\screens\analytics_screen.dart'
with open(analytics_file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Kavanozlarda bakiye bulunmuyor.', style: TextStyle(color: Colors.white54))))",
    "Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(AppStrings.get(ref, 'no_jar_balance') ?? 'Kavanozlarda bakiye bulunmuyor.', style: const TextStyle(color: Colors.white54))))"
)
content = content.replace(
    "'Toplam: $total Görev'",
    "(AppStrings.get(ref, 'total_tasks') ?? 'Toplam: {total} Görev').replaceAll('{total}', total.toString())"
)
content = content.replace(
    "'Toplam: $totalGoals Hedef'",
    "(AppStrings.get(ref, 'total_goals') ?? 'Toplam: {total} Hedef').replaceAll('{total}', totalGoals.toString())"
)

with open(analytics_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated missed texts in analytics_screen.dart")
