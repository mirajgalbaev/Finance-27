import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'daily': 'Daily',
        'monthly': 'Monthly',
        'yearly': 'Yearly',
        'monthly_upper': 'MONTHLY',
        'yearly_upper': 'YEARLY'
    },
    'tr': {
        'daily': 'Günlük',
        'monthly': 'Aylık',
        'yearly': 'Yıllık',
        'monthly_upper': 'AYLIK',
        'yearly_upper': 'YILLIK'
    },
    'ru': {
        'daily': 'Ежедневно',
        'monthly': 'Ежемесячно',
        'yearly': 'Ежегодно',
        'monthly_upper': 'ЕЖЕМЕСЯЧНО',
        'yearly_upper': 'ЕЖЕГОДНО'
    },
    'kg': {
        'daily': 'Күн сайын',
        'monthly': 'Ай сайын',
        'yearly': 'Жыл сайын',
        'monthly_upper': 'АЙ САЙЫН',
        'yearly_upper': 'ЖЫЛ САЙЫН'
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
    "items: ['Günlük', 'Aylık', 'Yıllık'].map((String value) {",
    """items: ['Günlük', 'Aylık', 'Yıllık'].map((String value) {
                                  String label = value;
                                  if (value == 'Günlük') label = AppStrings.get(ref, 'daily') ?? 'Günlük';
                                  if (value == 'Aylık') label = AppStrings.get(ref, 'monthly') ?? 'Aylık';
                                  if (value == 'Yıllık') label = AppStrings.get(ref, 'yearly') ?? 'Yıllık';"""
)
j_content = j_content.replace(
    "child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),",
    "child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),"
)
j_content = j_content.replace(
    "_spotFilter.toUpperCase() + ' ' : ''}${AppStrings.get(ref, 'war_report') ?? 'SAVAŞ RAPORU'}",
    "(_spotFilter == 'Aylık' ? (AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK') : (_spotFilter == 'Yıllık' ? (AppStrings.get(ref, 'yearly_upper') ?? 'YILLIK') : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK'))) + ' ' : ''}${AppStrings.get(ref, 'war_report') ?? 'SAVAŞ RAPORU'}"
)
j_content = j_content.replace(
    "_spotFilter.toUpperCase() : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK')} P&L'",
    "(_spotFilter == 'Aylık' ? (AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK') : (AppStrings.get(ref, 'yearly_upper') ?? 'YILLIK')) : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK')} P&L'"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
