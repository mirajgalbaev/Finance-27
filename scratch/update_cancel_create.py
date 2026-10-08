import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'cancel': 'Cancel',
        'create': 'Create'
    },
    'tr': {
        'cancel': 'İptal',
        'create': 'Oluştur'
    },
    'ru': {
        'cancel': 'Отмена',
        'create': 'Создать'
    },
    'kg': {
        'cancel': 'Жокко чыгаруу',
        'create': 'Түзүү'
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

print("Added cancel and create keys.")
