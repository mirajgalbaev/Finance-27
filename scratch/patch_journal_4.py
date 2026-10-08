import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'trades_upper': 'TRADES',
        'capital_label': 'Capital:',
        'open_status': 'Open'
    },
    'tr': {
        'trades_upper': 'İŞLEMLERİ',
        'capital_label': 'Sermaye:',
        'open_status': 'Açık'
    },
    'ru': {
        'trades_upper': 'СДЕЛКИ',
        'capital_label': 'Капитал:',
        'open_status': 'Открыто'
    },
    'kg': {
        'trades_upper': 'СООДАЛАР',
        'capital_label': 'Капитал:',
        'open_status': 'Ачык'
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


journal = r'C:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart'
with open(journal, 'r', encoding='utf-8') as f:
    j_content = f.read()

j_content = j_content.replace(
    "label.toUpperCase() + ' İŞLEMLERİ'",
    "label.toUpperCase() + ' ' + (AppStrings.get(ref, 'trades_upper') ?? 'İŞLEMLERİ')"
)
j_content = j_content.replace(
    "'Kaldıraç: ${t.leverage}'",
    "'${AppStrings.get(ref, 'leverage_label')?.replaceAll(' (Leverage)', '') ?? 'Kaldıraç'}: ${t.leverage}'"
)
j_content = j_content.replace(
    "const Text('Sermaye:'",
    "Text(AppStrings.get(ref, 'capital_label') ?? 'Sermaye:'"
)
j_content = j_content.replace(
    "'Açık'",
    "AppStrings.get(ref, 'open_status') ?? 'Açık'"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
