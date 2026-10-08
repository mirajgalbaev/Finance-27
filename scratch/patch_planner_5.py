import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'days_count': '{count} Days'
    },
    'tr': {
        'days_count': '{count} Gün'
    },
    'ru': {
        'days_count': '{count} Дней'
    },
    'kg': {
        'days_count': '{count} Күн'
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
                if f"'{k}':" not in content:
                    v_escaped = v.replace('$', '\\$').replace("'", "\\'")
                    new_lines.append(f"      '{k}': '{v_escaped}',")
        continue
    if current_lang is not None and line.strip() == '},':
        current_lang = None
    new_lines.append(line)

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))


planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "DateFormat('MMMM yyyy').format(_currentMonth)",
    "DateFormat('MMMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR')).format(_currentMonth)"
)
p_content = p_content.replace(
    "DateFormat('dd MMM yyyy').format(_globalDates.first)",
    "DateFormat('dd MMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR')).format(_globalDates.first)"
)
p_content = p_content.replace(
    "DateFormat('dd MMM').format(subTask.dates.first)",
    "DateFormat('dd MMM', AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR')).format(subTask.dates.first)"
)
p_content = p_content.replace(
    " : '${subTask.dates.length} Gün',",
    " : (AppStrings.get(ref, 'days_count')?.replaceAll('{count}', '${subTask.dates.length}') ?? '${subTask.dates.length} Gün'),"
)
p_content = p_content.replace(
    "Text('GÜNLÜK', textAlign: TextAlign.center,",
    "Text(AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK', textAlign: TextAlign.center,"
)
p_content = p_content.replace(
    "Text('AYLIK', textAlign: TextAlign.center,",
    "Text(AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK', textAlign: TextAlign.center,"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
