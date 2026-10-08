import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'time': 'Time',
        'direction': 'Direction',
        'leverage_label': 'Leverage',
        'entry_price': 'Entry Price',
        'exit_price_manual': 'Exit Price (Manual)',
        'trade_note': 'Trade Note (Lessons)',
        'cancel': 'Cancel',
        'save_upper': 'SAVE',
        'entry_label': 'Entry:',
        'exit_label': 'Exit:',
        'total_trades': 'TOTAL TRADES',
        'winning_trades': 'WINNING TRADES',
        'losing_trades': 'LOSING TRADES',
        'manual_exit': 'Manual Exit',
        'tp_hit': 'TP Hit',
        'sl_hit': 'SL Hit',
        'unleveraged_pnl': 'Unleveraged P&L ($)',
        'cancel_upper': 'CANCEL'
    },
    'tr': {
        'time': 'Saat',
        'direction': 'Yön',
        'leverage_label': 'Kaldıraç (Leverage)',
        'entry_price': 'Giriş Fiyatı',
        'exit_price_manual': 'Çıkış Fiyatı (Manuel)',
        'trade_note': 'İşlem Notu (Dersler)',
        'cancel': 'İptal',
        'save_upper': 'KAYDET',
        'entry_label': 'Giriş:',
        'exit_label': 'Çıkış:',
        'total_trades': 'TOPLAM İŞLEM',
        'winning_trades': 'KAZANAN İŞLEM',
        'losing_trades': 'KAYBEDEN İŞLEM',
        'manual_exit': 'Manuel Çıkış',
        'tp_hit': 'TP Vuruldu',
        'sl_hit': 'SL Vuruldu',
        'unleveraged_pnl': 'Kaldıraçsız P&L ($)',
        'cancel_upper': 'İPTAL'
    },
    'ru': {
        'time': 'Время',
        'direction': 'Направление',
        'leverage_label': 'Плечо (Leverage)',
        'entry_price': 'Цена входа',
        'exit_price_manual': 'Цена выхода (Ручная)',
        'trade_note': 'Заметка о сделке (Уроки)',
        'cancel': 'Отмена',
        'save_upper': 'СОХРАНИТЬ',
        'entry_label': 'Вход:',
        'exit_label': 'Выход:',
        'total_trades': 'ВСЕГО СДЕЛОК',
        'winning_trades': 'ВЫИГРЫШНЫЕ СДЕЛКИ',
        'losing_trades': 'УБЫТОЧНЫЕ СДЕЛКИ',
        'manual_exit': 'Ручной выход',
        'tp_hit': 'ТП достигнут',
        'sl_hit': 'СЛ достигнут',
        'unleveraged_pnl': 'P&L без плеча ($)',
        'cancel_upper': 'ОТМЕНА'
    },
    'kg': {
        'time': 'Убакыт',
        'direction': 'Багыт',
        'leverage_label': 'Левередж (Leverage)',
        'entry_price': 'Кирүү баасы',
        'exit_price_manual': 'Чыгуу баасы (Кол менен)',
        'trade_note': 'Соода эскертүүсү (Сабактар)',
        'cancel': 'Жокко чыгаруу',
        'save_upper': 'САКТОО',
        'entry_label': 'Кирүү:',
        'exit_label': 'Чыгуу:',
        'total_trades': 'БАРДЫК СООДАЛАР',
        'winning_trades': 'УТУШ СООДАЛАРЫ',
        'losing_trades': 'УТУЛУШ СООДАЛАРЫ',
        'manual_exit': 'Кол менен чыгуу',
        'tp_hit': 'ТП жетилди',
        'sl_hit': 'СЛ жетилди',
        'unleveraged_pnl': 'Левереджсиз P&L ($)',
        'cancel_upper': 'ЖОККО ЧЫГАРУУ'
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
                if f"'{k}':" not in content: # Avoid duplicates if already exists
                    new_lines.append(f"      '{k}': '{v}',")
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
    "_buildField('Saat'",
    "_buildField(AppStrings.get(ref, 'time') ?? 'Saat'"
)
j_content = j_content.replace(
    "labelText: 'Yön'",
    "labelText: AppStrings.get(ref, 'direction') ?? 'Yön'"
)
j_content = j_content.replace(
    "const Text('Kaldıraç (Leverage)'",
    "Text(AppStrings.get(ref, 'leverage_label') ?? 'Kaldıraç (Leverage)'"
)
j_content = j_content.replace(
    "_buildField('Giriş Fiyatı'",
    "_buildField(AppStrings.get(ref, 'entry_price') ?? 'Giriş Fiyatı'"
)
j_content = j_content.replace(
    "_buildField('Çıkış Fiyatı (Manuel)'",
    "_buildField(AppStrings.get(ref, 'exit_price_manual') ?? 'Çıkış Fiyatı (Manuel)'"
)
j_content = j_content.replace(
    "_buildField('Kaldıraçsız P&L (\$)'",
    "_buildField(AppStrings.get(ref, 'unleveraged_pnl') ?? 'Kaldıraçsız P&L (\$)'"
)
j_content = j_content.replace(
    "_buildField('İşlem Notu (Dersler)'",
    "_buildField(AppStrings.get(ref, 'trade_note') ?? 'İşlem Notu (Dersler)'"
)
j_content = j_content.replace(
    "const Text('İptal'",
    "Text(AppStrings.get(ref, 'cancel') ?? 'İptal'"
)
j_content = j_content.replace(
    "const Text('İPTAL'",
    "Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL'"
)
j_content = j_content.replace(
    "const Text('KAYDET'",
    "Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET'"
)
j_content = j_content.replace(
    "const Text('Giriş:'",
    "Text(AppStrings.get(ref, 'entry_label') ?? 'Giriş:'"
)
j_content = j_content.replace(
    "const Text('Çıkış:'",
    "Text(AppStrings.get(ref, 'exit_label') ?? 'Çıkış:'"
)
j_content = j_content.replace(
    "'TOPLAM İŞLEM'",
    "AppStrings.get(ref, 'total_trades') ?? 'TOPLAM İŞLEM'"
)
j_content = j_content.replace(
    "'KAZANAN İŞLEM'",
    "AppStrings.get(ref, 'winning_trades') ?? 'KAZANAN İŞLEM'"
)
j_content = j_content.replace(
    "'KAYBEDEN İŞLEM'",
    "AppStrings.get(ref, 'losing_trades') ?? 'KAYBEDEN İŞLEM'"
)
j_content = j_content.replace(
    "['Manuel Çıkış', 'TP Vuruldu', 'SL Vuruldu'].map",
    "[(AppStrings.get(ref, 'manual_exit') ?? 'Manuel Çıkış'), (AppStrings.get(ref, 'tp_hit') ?? 'TP Vuruldu'), (AppStrings.get(ref, 'sl_hit') ?? 'SL Vuruldu')].map"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "Text('İPTAL'",
    "Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL'"
)
p_content = p_content.replace(
    "Text('KAYDET'",
    "Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET'"
)
with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
