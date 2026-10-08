import os
import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix import
content = content.replace("import 'package:finance_27/ui/widgets/mt5_calculator_widget.dart';", "import 'package:finance_27/ui/widgets/mt5_symbol_selector.dart';")

# Fix `],` before `if (_selectedMarket == 'MT5')`
content = content.replace("                  ],\n                  if (_selectedMarket == 'MT5')\n                    SizedBox(width: 260, child: MT5SymbolSelector(pairCtrl: _pairCtrl, onChanged: (_) {}))\n                  else\n                    _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)', _pairCtrl, half: true),\n                  ],", 
'''                  if (_selectedMarket == 'MT5')
                    SizedBox(width: 260, child: MT5SymbolSelector(pairCtrl: _pairCtrl, onChanged: (_) {}))
                  else
                    _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)', _pairCtrl, half: true),
                  ],''')

# Remove leftover `MT5CalculatorWidget` in the Type Selector area
pattern = r"                  if \(_selectedMarket == 'MT5'\)\s*MT5CalculatorWidget\([\s\S]*?onRiskAmountCalculated: \(riskAmt\) => setState\(\(\) => _capCtrl\.text = riskAmt\.toString\(\)\),\s*\),\s*"
content = re.sub(pattern, "", content)

# Fix the dangling `];` or syntax issues
# If there's an issue near `1531` or `1627`, let's search for `, ,` or `] ;` or something.
# We had an issue around `actions: [` line 1532.
# Let's clean up any syntax errors by just letting the Dart analyzer find them after this pass.

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
