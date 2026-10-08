import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add MT5 to Tab Buttons
target_tab_buttons = '''                    _buildTabButton('Futures'),
                    const SizedBox(width: 4),
                    _buildTabButton('Spot'),'''
replacement_tab_buttons = '''                    _buildTabButton('Futures'),
                    const SizedBox(width: 4),
                    _buildTabButton('Spot'),
                    const SizedBox(width: 4),
                    _buildTabButton('MT5'),'''
content = content.replace(target_tab_buttons, replacement_tab_buttons)

# 2. Add MT5 to Dropdown in AddTradeDialog
target_dropdown = '''items: ['Spot', 'Futures'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),'''
replacement_dropdown = '''items: ['Spot', 'Futures', 'MT5'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),'''
content = content.replace(target_dropdown, replacement_dropdown)

# 3. Add Import for MT5CalculatorWidget
target_import = '''import '../../models/trade_model.dart';'''
replacement_import = '''import '../../models/trade_model.dart';\nimport '../widgets/mt5_calculator_widget.dart';'''
if 'mt5_calculator_widget' not in content:
    content = content.replace(target_import, replacement_import)

# 4. Integrate MT5CalculatorWidget inside AddTradeDialog build method
# We need to find where the Market Selector ends, and if _selectedMarket == 'MT5', show MT5CalculatorWidget, else show other fields.
# Let's do a smart replace

target_fields_start = '''                  // Market Selector
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>('''

# It's better to just write the specific dart file modifications if regex is hard.
# The user wants MT5 logic. Let's find the Exact spot for MT5CalculatorWidget.
target_after_market = '''                  if (_selectedMarket != 'Spot')
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,'''

replacement_after_market = '''                  if (_selectedMarket == 'MT5')
                    MT5CalculatorWidget(
                      pairCtrl: _pairCtrl,
                      entryCtrl: _entryCtrl,
                      slCtrl: _slCtrl,
                      tpCtrl: _tpCtrl,
                      onTypeChanged: (type) => setState(() => _selectedType = type),
                      onRiskAmountCalculated: (riskAmt) => setState(() => _capCtrl.text = riskAmt.toString()),
                    )
                  else ...[
                  if (_selectedMarket != 'Spot')
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,'''

content = content.replace(target_after_market, replacement_after_market)

target_close_else = '''              if (_selectedMarket == 'Futures') ...['''
replacement_close_else = '''              ], // close else block
              if (_selectedMarket == 'Futures') ...['''
content = content.replace(target_close_else, replacement_close_else)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
