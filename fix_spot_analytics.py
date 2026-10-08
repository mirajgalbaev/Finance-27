import os

loc_path = r"C:\Finance 27\lib\core\localization_provider.dart"
analytics_path = r"C:\Finance 27\lib\ui\screens\analytics_screen.dart"

with open(loc_path, "r", encoding="utf-8") as f:
    l = f.read()

new_keys_en = """
      'spot_wallet_title': 'Spot Wallet (Hodl & Spot)',
      'active_budget': 'Active Budget: ',
      'sold_upper': 'SOLD',
      'holding_upper': 'HOLDING',
      'amount_label': 'Amount: ',
"""
new_keys_tr = """
      'spot_wallet_title': 'Spot Cüzdan (Hodl & Spot)',
      'active_budget': 'Aktif Bütçe: ',
      'sold_upper': 'SATILDI',
      'holding_upper': 'ELİMDE',
      'amount_label': 'Miktar: ',
"""
new_keys_ru = """
      'spot_wallet_title': 'Спотовый кошелек (Hodl & Spot)',
      'active_budget': 'Активный бюджет: ',
      'sold_upper': 'ПРОДАНО',
      'holding_upper': 'В НАЛИЧИИ',
      'amount_label': 'Количество: ',
"""
new_keys_kg = """
      'spot_wallet_title': 'Спот капчыгы (Hodl & Spot)',
      'active_budget': 'Активдүү бюджет: ',
      'sold_upper': 'САТЫЛДЫ',
      'holding_upper': 'КОЛДО',
      'amount_label': 'Дөлөмү: ',
"""

l = l.replace("'undefined_text': 'Undefined',", "'undefined_text': 'Undefined'," + new_keys_en)
l = l.replace("'undefined_text': 'Belirsiz',", "'undefined_text': 'Belirsiz'," + new_keys_tr)
l = l.replace("'undefined_text': 'Не определено',", "'undefined_text': 'Не определено'," + new_keys_ru)
l = l.replace("'undefined_text': 'Белгисиз',", "'undefined_text': 'Белгисиз'," + new_keys_kg)

with open(loc_path, "w", encoding="utf-8") as f:
    f.write(l)

with open(analytics_path, "r", encoding="utf-8") as f:
    p = f.read()

# Replace strings
p = p.replace("Text('Spot Cüzdan (Hodl & Spot)'", "Text(AppStrings.get(ref, 'spot_wallet_title') ?? 'Spot Cüzdan (Hodl & Spot)'")
p = p.replace("Text('Aktif Bütçe: $${totalSpotBudget.toStringAsFixed(2)}'", "Text('${AppStrings.get(ref, 'active_budget') ?? 'Aktif Bütçe: '}$${totalSpotBudget.toStringAsFixed(2)}'")
p = p.replace("Text(isClosed ? 'SATILDI' : 'ELİMDE'", "Text(isClosed ? (AppStrings.get(ref, 'sold_upper') ?? 'SATILDI') : (AppStrings.get(ref, 'holding_upper') ?? 'ELİMDE')")
p = p.replace("Text('Miktar: '", "Text(AppStrings.get(ref, 'amount_label') ?? 'Miktar: '")

# Handle 'Belirsiz'
# Change Text(t.pair, ...) to check for undefined
pair_replace = "Text([\'belirsiz\', \'undefined\', \'не определено\', \'белгисиз\'].contains(t.pair.toLowerCase()) ? (AppStrings.get(ref, \'undefined_text\') ?? \'Belirsiz\') : t.pair"
p = p.replace("Text(t.pair,", pair_replace + ",")

with open(analytics_path, "w", encoding="utf-8") as f:
    f.write(p)

print("Updated Spot translations in analytics_screen.dart")
