import re

# We will inject the locale and text overrides into showDatePicker and showTimePicker
# in planner_screen.dart and goals_screen.dart

def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all showDatePicker(
    # We will just append these properties after firstDate or lastDate or similar.
    # Actually, a regex replacement might be tricky. Let's do it safely.

    # 1. showDatePicker
    # We find "lastDate: ..." or "initialDatePickerMode: ..." and insert our properties after them.
    # Example:
    # lastDate: DateTime.now().add(const Duration(days: 3650)),
    # We will replace `lastDate: (.*?),\n` with `lastDate: \1,\n                      cancelText: AppStrings.get(ref, 'cancel'),\n                      confirmText: AppStrings.get(ref, 'confirm'),\n                      helpText: AppStrings.get(ref, 'select_date') ?? 'Tarih Seçin',\n                      locale: ref.read(localeProvider) == 'kg' ? const Locale('ru') : Locale(ref.read(localeProvider)),\n`
    
    # Wait, some don't have trailing comma?
    
    # Let's just use string replacement on "showDatePicker(" to add a builder or just append to the arguments.
    # Let's replace "lastDate:" lines.
    content = re.sub(
        r"(lastDate:\s*[^,]+),",
        r"\1,\n                              cancelText: AppStrings.get(ref, 'cancel'),\n                              confirmText: AppStrings.get(ref, 'confirm'),\n                              helpText: AppStrings.get(ref, 'select_date') ?? 'Tarih Seçin',\n                              locale: ref.read(localeProvider) == 'kg' ? const Locale('ru') : Locale(ref.read(localeProvider)),",
        content
    )

    # 2. showTimePicker
    # For showTimePicker, the arguments are context, initialTime.
    # We replace "initialTime:" lines.
    content = re.sub(
        r"(initialTime:\s*[^,]+),",
        r"\1,\n                              cancelText: AppStrings.get(ref, 'cancel'),\n                              confirmText: AppStrings.get(ref, 'confirm'),\n                              helpText: AppStrings.get(ref, 'select_time') ?? 'Saat Seçin',",
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


patch_file(r'C:\Finance 27\lib\ui\screens\planner_screen.dart')
patch_file(r'C:\Finance 27\lib\ui\screens\goals_screen.dart')

# Add select_date and select_time to localization
loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'select_date': 'Select Date',
        'select_time': 'Select Time'
    },
    'tr': {
        'select_date': 'Tarih Seçin',
        'select_time': 'Saat Seçin'
    },
    'ru': {
        'select_date': 'Выберите дату',
        'select_time': 'Выберите время'
    },
    'kg': {
        'select_date': 'Күн тандаңыз',
        'select_time': 'Убакыт тандаңыз'
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

print("Patched pickers.")
