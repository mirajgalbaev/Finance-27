import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'daily_trade_journal': 'Daily Trade Journal',
        'new_trade': 'New Trade',
        'add_new_trade': 'Add New Trade',
        'delete_all_upper': 'DELETE ALL',
        'war_report': 'WAR REPORT',
        'daily_upper': 'DAILY',
        'net_upper': 'NET',
        'confirm_delete_all_trades': 'Are you sure? All PAST and FUTURE {tab} trades will be permanently deleted.',
        'delete_all_trades_title': 'Delete All {tab} Trades'
    },
    'tr': {
        'daily_trade_journal': 'Günlük İşlem Kaydı',
        'new_trade': 'Yeni İşlem',
        'add_new_trade': 'Yeni İşlem Ekle',
        'delete_all_upper': 'TÜMÜNÜ SİL',
        'war_report': 'SAVAŞ RAPORU',
        'daily_upper': 'GÜNLÜK',
        'net_upper': 'NET',
        'confirm_delete_all_trades': 'Emin misiniz? Geçmiş ve Gelecek TÜM {tab} işlemleri kalıcı olarak silinecektir.',
        'delete_all_trades_title': 'Tüm "{tab}" İşlemlerini Sil'
    },
    'ru': {
        'daily_trade_journal': 'Журнал дневных сделок',
        'new_trade': 'Новая сделка',
        'add_new_trade': 'Добавить сделку',
        'delete_all_upper': 'УДАЛИТЬ ВСЕ',
        'war_report': 'ОТЧЕТ',
        'daily_upper': 'ЕЖЕДНЕВНО',
        'net_upper': 'НЕТТО',
        'confirm_delete_all_trades': 'Вы уверены? Все ПРОШЛЫЕ и БУДУЩИЕ сделки {tab} будут удалены навсегда.',
        'delete_all_trades_title': 'Удалить все сделки "{tab}"'
    },
    'kg': {
        'daily_trade_journal': 'Күнүмдүк соода журналы',
        'new_trade': 'Жаңы соода',
        'add_new_trade': 'Жаңы соода кошуу',
        'delete_all_upper': 'БААРЫН ӨЧҮРҮҮ',
        'war_report': 'ОТЧЕТ',
        'daily_upper': 'КҮНДҮК',
        'net_upper': 'ТАЗА',
        'confirm_delete_all_trades': 'Ишенесизби? БАРДЫК өткөн жана келечектеги {tab} соодалары биротоло жок кылынат.',
        'delete_all_trades_title': 'Бардык "{tab}" соодаларын өчүрүү'
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

final_content = '\n'.join(new_lines)
if "getTranslatedDays" not in final_content:
    days_helper = """
  static List<String> getTranslatedDays(String localeStr) {
    if (localeStr == 'tr') return ['PAZ', 'PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CTS'];
    if (localeStr == 'ru') return ['ВС', 'ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];
    if (localeStr == 'kg') return ['ЖШ', 'ДШ', 'ШЕ', 'ША', 'БЕ', 'ЖУ', 'ИШ'];
    return ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  }
"""
    final_content = final_content.replace("static String getDateFormatLocale(String locale) {", days_helper + "\n  static String getDateFormatLocale(String locale) {")

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write(final_content)


journal = r'C:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart'
with open(journal, 'r', encoding='utf-8') as f:
    j_content = f.read()

j_content = j_content.replace(
    "Text('Günlük İşlem Kaydı - $dateStr'",
    "Text('${AppStrings.get(ref, 'daily_trade_journal') ?? 'Günlük İşlem Kaydı'} - $dateStr'"
)
j_content = j_content.replace(
    "const Text('Yeni İşlem')",
    "Text(AppStrings.get(ref, 'new_trade') ?? 'Yeni İşlem')"
)
j_content = j_content.replace(
    "const Text('Yeni İşlem Ekle'",
    "Text(AppStrings.get(ref, 'add_new_trade') ?? 'Yeni İşlem Ekle'"
)
j_content = j_content.replace(
    "Text('$_selectedTab Sil')",
    "Text('$_selectedTab ${AppStrings.get(ref, 'delete_upper') ?? 'SİL'}')"
)
j_content = j_content.replace(
    "const Text('SİL'",
    "Text(AppStrings.get(ref, 'delete_upper') ?? 'SİL'"
)
j_content = j_content.replace(
    "const Text('TÜMÜNÜ SİL'",
    "Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TÜMÜNÜ SİL'"
)
j_content = j_content.replace(
    "Text('Tüm \"$_selectedTab\" İşlemlerini Sil'",
    "Text((AppStrings.get(ref, 'delete_all_trades_title') ?? 'Tüm \"{tab}\" İşlemlerini Sil').replaceAll('{tab}', _selectedTab)"
)
j_content = j_content.replace(
    "Text('Emin misiniz? Geçmiş ve Gelecek TÜM $_selectedTab işlemleri kalıcı olarak silinecektir.'",
    "Text((AppStrings.get(ref, 'confirm_delete_all_trades') ?? 'Emin misiniz? Geçmiş ve Gelecek TÜM {tab} işlemleri kalıcı olarak silinecektir.').replaceAll('{tab}', _selectedTab)"
)
j_content = j_content.replace(
    "SAVAŞ RAPORU'.toUpperCase()",
    "${AppStrings.get(ref, 'war_report') ?? 'SAVAŞ RAPORU'}'.toUpperCase()"
)
j_content = j_content.replace(
    "NET ${_selectedTab == 'Spot' && _spotFilter != 'Günlük' ? _spotFilter.toUpperCase() : 'GÜNLÜK'} P&L",
    "${AppStrings.get(ref, 'net_upper') ?? 'NET'} ${_selectedTab == 'Spot' && _spotFilter != 'Günlük' ? _spotFilter.toUpperCase() : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK')} P&L"
)


with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)


planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) {",
    "AppStrings.getTranslatedDays(locale).map((day) {"
)

p_content = p_content.replace(
    "const Text('TÜMÜNÜ SİL'",
    "Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TÜMÜNÜ SİL'"
)
p_content = p_content.replace(
    "Text('TÜMÜNÜ SİL'",
    "Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TÜMÜNÜ SİL'"
)
p_content = p_content.replace(
    "const Text('SİL'",
    "Text(AppStrings.get(ref, 'delete_upper') ?? 'SİL'"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
