import os
import re

path = 'lib/core/localization_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add English
content = content.replace(
    "'buy_tp_1_default': 'Take Profit (TP) Target',",
    "'buy_tp_1_default': 'Take Profit (TP) Target',\n      'mt5_symbol': 'Symbol',\n      'mt5_balance': 'Account Balance ($)',\n      'mt5_risk_pct': 'Risk Percentage (%)',\n      'mt5_entry': 'Entry Price',\n      'mt5_sl': 'Stop Loss (SL)',\n      'mt5_tp': 'Take Profit (TP)',\n      'mt5_req_lot': 'Required Lot Size:',\n      'mt5_act_risk': 'Actual Risk:',\n      'mt5_margin': 'Req. Margin:',\n      'mt5_error': 'Error:',\n      'mt5_custom_symbol': 'Type symbol...',",
    1
)

# Add Turkish
content = content.replace(
    "'buy_tp_1_default': 'AlД±m TP-1 (VarsayД±lan)',",
    "'buy_tp_1_default': 'AlД±m TP-1 (VarsayД±lan)',\n      'mt5_symbol': 'Sembol',\n      'mt5_balance': 'Hesap Bakiyesi ($)',\n      'mt5_risk_pct': 'Risk YГјzdesi (%)',\n      'mt5_entry': 'GiriЕџ FiyatД± (Entry)',\n      'mt5_sl': 'Zarar Kes (SL)',\n      'mt5_tp': 'KГўr Al (TP)',\n      'mt5_req_lot': 'Gerekli Lot Hacmi:',\n      'mt5_act_risk': 'GerГ§ekleЕџecek Risk:',\n      'mt5_margin': 'Gerekli Teminat:',\n      'mt5_error': 'Hata:',\n      'mt5_custom_symbol': 'Sembol yazД±n...',",
    1
)

# Add Russian
content = content.replace(
    "'buy_tp_1_default': 'Take Profit (TP) Р¦РµР»СЊ',",
    "'buy_tp_1_default': 'Take Profit (TP) Р¦РµР»СЊ',\n      'mt5_symbol': 'РЎРёРјРІРѕР»',\n      'mt5_balance': 'Р‘Р°Р»Р°РЅСЃ СЃС‡РµС‚Р° ($)',\n      'mt5_risk_pct': 'РџСЂРѕС†РµРЅС‚ СЂРёСЃРєР° (%)',\n      'mt5_entry': 'Р¦РµРЅР° РІС…РѕРґР°',\n      'mt5_sl': 'Stop Loss (SL)',\n      'mt5_tp': 'Take Profit (TP)',\n      'mt5_req_lot': 'РўСЂРµР±СѓРµРјС‹Р№ Р»РѕС‚:',\n      'mt5_act_risk': 'Р¤Р°РєС‚РёС‡РµСЃРєРёР№ СЂРёСЃРє:',\n      'mt5_margin': 'РњР°СЂР¶Р°:',\n      'mt5_error': 'РћС€РёР±РєР°:',\n      'mt5_custom_symbol': 'Р’РІРµРґРёС‚Рµ СЃРёРјРІРѕР»...',",
    1
)

# Add Kyrgyz
content = content.replace(
    "'buy_tp_1_default': 'Take Profit (TP) РњР°РєСЃР°С‚С‹',",
    "'buy_tp_1_default': 'Take Profit (TP) РњР°РєСЃР°С‚С‹',\n      'mt5_symbol': 'РЎРёРјРІРѕР»',\n      'mt5_balance': 'РРЃСЃРµРї Р±Р°Р»Р°РЅСЃС‹ ($)',\n      'mt5_risk_pct': 'РўРѕР±РѕРєРµР»РґРёРє РїР°Р№С‹Р·С‹ (%)',\n      'mt5_entry': 'РљРёСЂТЇТЇ Р±Р°Р°СЃС‹',\n      'mt5_sl': 'Stop Loss (SL)',\n      'mt5_tp': 'Take Profit (TP)',\n      'mt5_req_lot': 'РўР°Р»Р°Рї РєС‹Р»С‹РЅРіР°РЅ Р»РѕС‚:',\n      'mt5_act_risk': 'РўРѕР±РѕРєРµР»РґРёРє:',\n      'mt5_margin': 'РњР°СЂР¶Р°:',\n      'mt5_error': 'РљР°С‚Р°:',\n      'mt5_custom_symbol': 'РЎРёРјРІРѕР» Р¶Р°Р·С‹ТЈС‹Р·...',",
    1
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
