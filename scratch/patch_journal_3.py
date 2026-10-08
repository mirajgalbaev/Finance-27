import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'no_trades_found': 'No trades found for this market.',
        'add_new_exchange': 'Add New Exchange',
        'exchange_name_hint': 'Exchange Name (e.g., Kraken)',
        'exchange_label': 'Exchange',
        'delete_exchange_tooltip': 'Delete Exchange',
        'min_1_exchange': 'At least 1 exchange must remain.',
        'pair_hint': 'Pair (e.g., BTC/USDT)',
        'market_label': 'Market',
        'close_type_label': 'Close Type'
    },
    'tr': {
        'no_trades_found': 'Bu piyasa için işlem bulunamadı.',
        'add_new_exchange': 'Yeni Borsa Ekle',
        'exchange_name_hint': 'Borsa Adı (Örn: Kraken)',
        'exchange_label': 'Borsa',
        'delete_exchange_tooltip': 'Borsayı Sil',
        'min_1_exchange': 'En az 1 borsa kalmalıdır.',
        'pair_hint': 'Parite (Örn: BTC/USDT)',
        'market_label': 'Piyasa',
        'close_type_label': 'Kapanış Türü'
    },
    'ru': {
        'no_trades_found': 'Сделки для этого рынка не найдены.',
        'add_new_exchange': 'Добавить биржу',
        'exchange_name_hint': 'Название биржи (напр., Kraken)',
        'exchange_label': 'Биржа',
        'delete_exchange_tooltip': 'Удалить биржу',
        'min_1_exchange': 'Должна остаться хотя бы 1 биржа.',
        'pair_hint': 'Пара (напр., BTC/USDT)',
        'market_label': 'Рынок',
        'close_type_label': 'Тип закрытия'
    },
    'kg': {
        'no_trades_found': 'Бул базар үчүн соода табылган жок.',
        'add_new_exchange': 'Жаңы биржа кошуу',
        'exchange_name_hint': 'Биржанын аты (мис., Kraken)',
        'exchange_label': 'Биржа',
        'delete_exchange_tooltip': 'Биржаны өчүрүү',
        'min_1_exchange': 'Кеминде 1 биржа калышы керек.',
        'pair_hint': 'Пара (мис., BTC/USDT)',
        'market_label': 'Базар',
        'close_type_label': 'Жабылуу түрү'
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
    "'Bu piyasa için işlem bulunamadı.'",
    "AppStrings.get(ref, 'no_trades_found') ?? 'Bu piyasa için işlem bulunamadı.'"
)
j_content = j_content.replace(
    "'Yeni Borsa Ekle'",
    "AppStrings.get(ref, 'add_new_exchange') ?? 'Yeni Borsa Ekle'"
)
j_content = j_content.replace(
    "'Borsa Adı (Örn: Kraken)'",
    "AppStrings.get(ref, 'exchange_name_hint') ?? 'Borsa Adı (Örn: Kraken)'"
)
j_content = j_content.replace(
    "labelText: 'Borsa'",
    "labelText: AppStrings.get(ref, 'exchange_label') ?? 'Borsa'"
)
j_content = j_content.replace(
    "'Borsayı Sil'",
    "AppStrings.get(ref, 'delete_exchange_tooltip') ?? 'Borsayı Sil'"
)
j_content = j_content.replace(
    "'En az 1 borsa kalmalıdır.'",
    "AppStrings.get(ref, 'min_1_exchange') ?? 'En az 1 borsa kalmalıdır.'"
)
j_content = j_content.replace(
    "_buildField('Parite (Örn: BTC/USDT)'",
    "_buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)'"
)
j_content = j_content.replace(
    "labelText: 'Piyasa'",
    "labelText: AppStrings.get(ref, 'market_label') ?? 'Piyasa'"
)
j_content = j_content.replace(
    "labelText: 'Kapanış Türü'",
    "labelText: AppStrings.get(ref, 'close_type_label') ?? 'Kapanış Türü'"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
