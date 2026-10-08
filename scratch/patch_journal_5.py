import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'export_btn': 'Export',
        'pending_status': 'Pending...',
        'summary_upper': 'SUMMARY',
        'won_money': 'PROFIT',
        'lost_money': 'LOSS',
        'win_rate_upper': 'WIN RATE',
        'pnl_chart_upper': 'PNL CHART',
        'global_grand_total': 'GLOBAL GRAND TOTAL',
        'end_of_day_notes': 'END OF DAY NOTES',
        'no_data': 'No Data',
        'undefined_text': 'Undefined'
    },
    'tr': {
        'export_btn': 'Dışarı Aktar',
        'pending_status': 'Bekliyor...',
        'summary_upper': 'ÖZETİ',
        'won_money': 'KAZANILAN PARA',
        'lost_money': 'KAYBEDİLEN PARA',
        'win_rate_upper': 'WIN RATE',
        'pnl_chart_upper': 'PNL GRAFİĞİ',
        'global_grand_total': 'GENEL TOPLAM ÖZETİ',
        'end_of_day_notes': 'GÜN SONU NOTLARI',
        'no_data': 'Veri Yok',
        'undefined_text': 'Belirsiz'
    },
    'ru': {
        'export_btn': 'Экспорт',
        'pending_status': 'В ожидании...',
        'summary_upper': 'СВОДКА',
        'won_money': 'ПРИБЫЛЬ',
        'lost_money': 'УБЫТОК',
        'win_rate_upper': 'WIN RATE',
        'pnl_chart_upper': 'ГРАФИК PNL',
        'global_grand_total': 'ОБЩИЙ ИТОГ',
        'end_of_day_notes': 'ЗАМЕТКИ В КОНЦЕ ДНЯ',
        'no_data': 'Нет данных',
        'undefined_text': 'Не определено'
    },
    'kg': {
        'export_btn': 'Экспорттоо',
        'pending_status': 'Күтүлүүдө...',
        'summary_upper': 'КЫСКАЧА',
        'won_money': 'ПАЙДА',
        'lost_money': 'ЧЫГЫМ',
        'win_rate_upper': 'WIN RATE',
        'pnl_chart_upper': 'PNL ГРАФИГИ',
        'global_grand_total': 'ЖАЛПЫ ЖЫЙЫНТЫК',
        'end_of_day_notes': 'КҮНДҮН АЯГЫНДАГЫ ЭСКЕРТҮҮЛӨР',
        'no_data': 'Маалымат жок',
        'undefined_text': 'Белгисиз'
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
    "const Text('Dışarı Aktar')",
    "Text(AppStrings.get(ref, 'export_btn') ?? 'Dışarı Aktar')"
)
j_content = j_content.replace(
    "const Text('Bekliyor...'",
    "Text(AppStrings.get(ref, 'pending_status') ?? 'Bekliyor...'"
)
j_content = j_content.replace(
    "Text('$exchange ÖZETİ'",
    "Text('${exchange.toUpperCase()} ${AppStrings.get(ref, 'summary_upper') ?? 'ÖZETİ'}'"
)
j_content = j_content.replace(
    "'KAZANILAN PARA'",
    "AppStrings.get(ref, 'won_money') ?? 'KAZANILAN PARA'"
)
j_content = j_content.replace(
    "'KAYBEDİLEN PARA'",
    "AppStrings.get(ref, 'lost_money') ?? 'KAYBEDİLEN PARA'"
)
j_content = j_content.replace(
    "const Text('WIN RATE'",
    "Text(AppStrings.get(ref, 'win_rate_upper') ?? 'WIN RATE'"
)
j_content = j_content.replace(
    "const Text('PNL GRAFİĞİ'",
    "Text(AppStrings.get(ref, 'pnl_chart_upper') ?? 'PNL GRAFİĞİ'"
)
j_content = j_content.replace(
    "const Text('GENEL TOPLAM ÖZETİ'",
    "Text(AppStrings.get(ref, 'global_grand_total') ?? 'GENEL TOPLAM ÖZETİ'"
)
j_content = j_content.replace(
    "const Text('GÜN SONU NOTLARI'",
    "Text(AppStrings.get(ref, 'end_of_day_notes') ?? 'GÜN SONU NOTLARI'"
)
j_content = j_content.replace(
    "Text('Veri Yok'",
    "Text(AppStrings.get(ref, 'no_data') ?? 'Veri Yok'"
)
j_content = j_content.replace(
    "'Belirsiz'",
    "AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz'"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
