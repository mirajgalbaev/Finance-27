import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will find the second occurrence of the leverage slider inside the Wrap and replace it with the TP section.
# The bad section starts after `_buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),`
pattern = r"_buildField\('Stop Loss \(SL\)', _slCtrl, half: true, isNum: true\),\s*if \(_selectedMarket == 'Futures' \|\| _selectedMarket == 'MT5'\) \.\.\.\[([\s\S]*?)const Divider\(color: Colors\.white12, height: 32\),"

replacement = '''_buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),
                   ],
                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
                     _buildField('Take Profit (TP-1)', _tpCtrl, half: true, isNum: true),
                     for (int i = 0; i < _additionalTpCtrls.length; i++)
                       _buildField('TP-${i + 2}', _additionalTpCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _additionalTpCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.blueAccent),
                         label: Text(AppStrings.get(ref, 'add_second_tp') ?? 'İkinci TP Ekle', style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                       ),
                     ),
                   ],
                   if (_selectedMarket == 'Spot') ...[
                     _buildField(AppStrings.get(ref, 'buy_tp_1_default') ?? 'Alım TP-1 (Varsayılan)', _tpCtrl, half: true, isNum: true),
                     for (int i = 0; i < _buyTargetsCtrls.length; i++)
                       _buildField('${AppStrings.get(ref, 'buy_tp') ?? 'Alım TP'}-${i + 2}', _buyTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _buyTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                         label: Text(AppStrings.get(ref, 'add_buy_target') ?? 'Alım Hedefi Ekle', style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
                       ),
                     ),
                     for (int i = 0; i < _sellTargetsCtrls.length; i++)
                       _buildField('${AppStrings.get(ref, 'sell_tp') ?? 'Satış TP'}-${i + 1}', _sellTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _sellTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.orangeAccent),
                         label: Text(AppStrings.get(ref, 'add_sell_target') ?? 'Satış Hedefi Ekle', style: const TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                       ),
                     ),
                   ],
                ]
              ),
              const Divider(color: Colors.white12, height: 32),'''

content = re.sub(pattern, replacement, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
