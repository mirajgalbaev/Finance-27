import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Hide Exchange Dropdown when MT5 is selected
# Look for Exchange Selector
pattern_exchange = r"(// Exchange Selector\s*SizedBox\()"
replacement_exchange = '''// Exchange Selector
                  if (_selectedMarket != 'MT5')
                  SizedBox('''
content = re.sub(pattern_exchange, replacement_exchange, content, count=1)

# 2. Fix the Slider for MT5
# For MT5, we shouldn't use an integer slider (1 to 125). We should just show a decimal TextField for "Lot".
pattern_leverage = r"if \(_selectedMarket == 'Futures' \|\| _selectedMarket == 'MT5'\) \.\.\.\[([\s\S]*?)const Divider\(color: Colors\.white12, height: 32\),"
def replace_leverage(m):
    return '''if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
                const SizedBox(height: 16),
                Text(_selectedMarket == 'MT5' ? (AppStrings.get(ref, 'mt5_req_lot')?.replaceAll(':','') ?? 'Lot Hacmi') : (AppStrings.get(ref, 'leverage_label') ?? 'Kaldıraç (Leverage)'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Row(
                  children: [
                    if (_selectedMarket != 'MT5')
                      Expanded(
                        child: Slider(
                          value: _leverage,
                          min: 1,
                          max: 125,
                          divisions: 124,
                          activeColor: Colors.blueAccent,
                          label: '${_leverage.toInt()}x',
                          onChanged: (v) {
                            setState(() {
                              _leverage = v;
                              _leverageCtrl.text = v.toInt().toString();
                              _calculatePnL();
                            });
                          },
                        ),
                      ),
                    SizedBox(
                      width: _selectedMarket == 'MT5' ? 260 : 60,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        controller: _leverageCtrl,
                        onChanged: (val) {
                          double? l = double.tryParse(val);
                          if (l != null && l > 0) {
                            setState(() {
                              _leverage = l;
                              _calculatePnL();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          suffixText: _selectedMarket == 'MT5' ? 'Lot' : 'x', 
                          suffixStyle: const TextStyle(color: Colors.white54),
                          filled: _selectedMarket == 'MT5',
                          fillColor: Colors.black26,
                          border: _selectedMarket == 'MT5' ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none) : null,
                        ),
                      ),
                    )
                  ],
                )
              ],
              const Divider(color: Colors.white12, height: 32),
'''
content = re.sub(pattern_leverage, replace_leverage, content)

# 3. Update `_calculatePnL` for MT5 Lot math
# Replace `if (cap <= 0 || entry <= 0) return;` with MT5-aware version
content = content.replace("if (cap <= 0 || entry <= 0) return;", "if (entry <= 0 || (_selectedMarket != 'MT5' && cap <= 0)) return;")
# Replace `double qty = (cap * lev) / entry;` with MT5 math
# Wait, for this I need to make sure MT5MockSymbols is imported in daily_trade_journal_screen.dart
if "import '../../core/mt5/mt5_symbols.dart';" not in content:
    content = content.replace("import 'package:finance_27/ui/widgets/mt5_symbol_selector.dart';", "import 'package:finance_27/ui/widgets/mt5_symbol_selector.dart';\nimport 'package:finance_27/core/mt5/mt5_symbols.dart';")

pattern_qty = r"double qty = \(cap \* lev\) / entry;"
replacement_qty = '''double qty = (cap * lev) / entry;
      if (_selectedMarket == 'MT5') {
        double contractSize = 100000;
        try {
          final spec = MT5MockSymbols.getSymbolSpec(_pairCtrl.text.toUpperCase());
          contractSize = spec.contractSize;
        } catch (_) {}
        qty = lev * contractSize; // lev holds the Lot Size
      }'''
content = content.replace(pattern_qty, replacement_qty)

# 4. Make sure PnL Pct uses a fixed denominator if `cap` is 0 in MT5
pattern_pct = r"double pnlPct = cap > 0 \? \(pnlAmt / cap\) \* 100 : 0;"
replacement_pct = '''double pnlPct = cap > 0 ? (pnlAmt / cap) * 100 : (_selectedMarket == 'MT5' && entry > 0 ? (pnlAmt / (qty * entry)) * 100 : 0);'''
content = content.replace(pattern_pct, replacement_pct)

# 5. Fix Save formatting for MT5 Lot
# Search for `leverage: '${_leverage.toInt()}x',`
# Replace with `leverage: _selectedMarket == 'MT5' ? '${_leverage} Lot' : '${_leverage.toInt()}x',`
content = content.replace("leverage: '${_leverage.toInt()}x',", "leverage: _selectedMarket == 'MT5' ? '${_leverage} Lot' : '${_leverage.toInt()}x',")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
