import os
import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure MT5SymbolSelector is imported
if "import '../../widgets/mt5_symbol_selector.dart';" not in content:
    content = content.replace("import '../../widgets/mt5_calculator_widget.dart';", "import '../../widgets/mt5_symbol_selector.dart';")

# 1. Exchange and Pair rendering
# We have:
#                  _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)', _pairCtrl, half: true),
#                  ],
# We will replace that with logic that handles MT5SymbolSelector
pattern_pair = r"\_buildField\(AppStrings\.get\(ref, 'pair_hint'\) \?\? 'Parite \(Örn: BTC/USDT\)', \_pairCtrl, half: true\),\s*\],"
replacement_pair = '''
                  if (_selectedMarket == 'MT5')
                    SizedBox(width: 260, child: MT5SymbolSelector(pairCtrl: _pairCtrl, onChanged: (_) {}))
                  else
                    _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)', _pairCtrl, half: true),
                  ],'''
content = re.sub(pattern_pair, replacement_pair, content, count=1, flags=re.DOTALL)

# 2. Remove MT5CalculatorWidget entirely
pattern_calc = r"if \(_selectedMarket == 'MT5'\)\s*MT5CalculatorWidget\([\s\S]*?\),"
content = re.sub(pattern_calc, "", content)

# 3. Fix the layout array
# Re-enable standard fields for MT5 (if they were hidden by `if (_selectedMarket != 'MT5') ...[`)
content = content.replace("if (_selectedMarket != 'MT5') ...[", "")
content = content.replace("                   ],\n                   if (_selectedMarket == 'Futures') ...[", "                   if (_selectedMarket == 'Futures') ...[")
content = content.replace("                   ],\n                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[", "                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[")
content = content.replace("if (_selectedMarket == 'Futures') ...[", "if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[")

# 4. Fix Exchange String
content = content.replace("String exStr = _exchangeCtrl.text.isEmpty ? 'Bilinmiyor' : _exchangeCtrl.text;", "String exStr = _selectedMarket == 'MT5' ? 'MT5' : (_exchangeCtrl.text.isEmpty ? 'Bilinmiyor' : _exchangeCtrl.text);")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
