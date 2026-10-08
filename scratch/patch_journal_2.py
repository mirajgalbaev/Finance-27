import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'used_margin': 'USED MARGIN',
        'margin_amount': 'Margin ($)',
        'add_second_tp': 'Add Second TP',
        'auto_pnl_pct': 'Auto P&L (%)',
        'auto_pnl_amt': 'Auto P&L ($)',
        'equivalent_volume': 'Equivalent Vol ($)'
    },
    'tr': {
        'used_margin': 'KULLANILAN MALİYET',
        'margin_amount': 'Maliyet (Margin) ($)',
        'add_second_tp': 'İkinci TP Ekle',
        'auto_pnl_pct': 'Otomatik P&L (%)',
        'auto_pnl_amt': 'Otomatik P&L ($)',
        'equivalent_volume': 'Eşdeğer Hacim ($)'
    },
    'ru': {
        'used_margin': 'ИСПОЛЬЗ. МАРЖА',
        'margin_amount': 'Маржа ($)',
        'add_second_tp': 'Доб. второй TP',
        'auto_pnl_pct': 'Авто P&L (%)',
        'auto_pnl_amt': 'Авто P&L ($)',
        'equivalent_volume': 'Эквив. объем ($)'
    },
    'kg': {
        'used_margin': 'КОЛДОНУЛГАН МАРЖА',
        'margin_amount': 'Маржа ($)',
        'add_second_tp': 'Экинчи TP кошуу',
        'auto_pnl_pct': 'Авто P&L (%)',
        'auto_pnl_amt': 'Авто P&L ($)',
        'equivalent_volume': 'Эквиваленттүү көлөм ($)'
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
                    # properly escape $ for dart string maps!
                    v_escaped = v.replace('$', '\\$')
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
    "'KULLANILAN MALİYET'",
    "AppStrings.get(ref, 'used_margin') ?? 'KULLANILAN MALİYET'"
)
j_content = j_content.replace(
    "'Maliyet (Margin) \$'",
    "AppStrings.get(ref, 'margin_amount') ?? 'Maliyet (Margin) \$'"
)
j_content = j_content.replace(
    "const Text('İkinci TP Ekle'",
    "Text(AppStrings.get(ref, 'add_second_tp') ?? 'İkinci TP Ekle'"
)
j_content = j_content.replace(
    "'Otomatik P&L (%)'",
    "AppStrings.get(ref, 'auto_pnl_pct') ?? 'Otomatik P&L (%)'"
)
j_content = j_content.replace(
    "'Otomatik P&L (\$)'",
    "AppStrings.get(ref, 'auto_pnl_amt') ?? 'Otomatik P&L (\$)'"
)
j_content = j_content.replace(
    "'Eşdeğer Hacim (\$)'",
    "AppStrings.get(ref, 'equivalent_volume') ?? 'Eşdeğer Hacim (\$)'"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
