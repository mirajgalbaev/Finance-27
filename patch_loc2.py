import os
import re

path = 'lib/core/localization_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add Turkish
if "'mt5_symbol': 'Sembol'," not in content:
    content = content.replace(
        "'buy_tp_1_default': 'Alım TP-1 (Varsayılan)',",
        "'buy_tp_1_default': 'Alım TP-1 (Varsayılan)',\n      'mt5_symbol': 'Sembol',\n      'mt5_balance': 'Hesap Bakiyesi (\\$)',\n      'mt5_risk_pct': 'Risk Yüzdesi (%)',\n      'mt5_entry': 'Giriş Fiyatı (Entry)',\n      'mt5_sl': 'Zarar Kes (SL)',\n      'mt5_tp': 'Kâr Al (TP)',\n      'mt5_req_lot': 'Gerekli Lot Hacmi:',\n      'mt5_act_risk': 'Gerçekleşecek Risk:',\n      'mt5_margin': 'Gerekli Teminat:',\n      'mt5_error': 'Hata:',\n      'mt5_custom_symbol': 'Sembol yazın...',",
        1
    )

# Add Russian
if "'mt5_symbol': 'Символ'," not in content:
    content = content.replace(
        "'buy_tp_1_default': 'Take Profit (TP) Цель',",
        "'buy_tp_1_default': 'Take Profit (TP) Цель',\n      'mt5_symbol': 'Символ',\n      'mt5_balance': 'Баланс счета (\\$)',\n      'mt5_risk_pct': 'Процент риска (%)',\n      'mt5_entry': 'Цена входа',\n      'mt5_sl': 'Stop Loss (SL)',\n      'mt5_tp': 'Take Profit (TP)',\n      'mt5_req_lot': 'Требуемый лот:',\n      'mt5_act_risk': 'Фактический риск:',\n      'mt5_margin': 'Маржа:',\n      'mt5_error': 'Ошибка:',\n      'mt5_custom_symbol': 'Введите символ...',",
        1
    )

# Add Kyrgyz
if "'mt5_symbol': 'Символ'," not in content: # Note: Kyrgyz translation uses Символ too
    content = content.replace(
        "'buy_tp_1_default': 'Take Profit (TP) Максаты',",
        "'buy_tp_1_default': 'Take Profit (TP) Максаты',\n      'mt5_symbol': 'Символ',\n      'mt5_balance': 'Эсеп балансы (\\$)',\n      'mt5_risk_pct': 'Тобокелдик пайызы (%)',\n      'mt5_entry': 'Кирүү баасы',\n      'mt5_sl': 'Stop Loss (SL)',\n      'mt5_tp': 'Take Profit (TP)',\n      'mt5_req_lot': 'Талап кылынган лот:',\n      'mt5_act_risk': 'Тобокелдик:',\n      'mt5_margin': 'Маржа:',\n      'mt5_error': 'Ката:',\n      'mt5_custom_symbol': 'Символ жазыңыз...',",
        1
    )

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
