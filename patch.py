import os

path = 'lib/core/localization_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# EN
content = content.replace(
    "'exit_price_manual': 'Exit Price (Manual)',",
    "'exit_price_manual': 'Exit Price (Manual)',\n      'buy_tp_1_default': 'Take Profit (TP) Target',"
)

# TR
content = content.replace(
    "'exit_price_manual': 'Çıkış Fiyatı (Manuel)',",
    "'exit_price_manual': 'Çıkış Fiyatı (Manuel)',\n      'buy_tp_1_default': 'Kâr Al (TP) Hedefi',"
)

# RU
content = content.replace(
    "'exit_price_manual': 'Цена выхода (Ручная)',",
    "'exit_price_manual': 'Цена выхода (Ручная)',\n      'buy_tp_1_default': 'Цель Тейк-Профит (TP)',"
)

# KG
content = content.replace(
    "'exit_price_manual': 'Чыгуу баасы (Кол менен)',",
    "'exit_price_manual': 'Чыгуу баасы (Кол менен)',\n      'buy_tp_1_default': 'Take Profit (TP) Максаты',"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS")
