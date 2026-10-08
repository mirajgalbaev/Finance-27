import os
import re

path = 'c:/Finance 27/lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add fields to AddTradeDialogState
pattern_fields = r'(final _tpCtrl = TextEditingController\(\);)'
rep_fields = r'''\1
  final List<TextEditingController> _additionalTpCtrls = [];
  final List<TextEditingController> _buyTargetsCtrls = [];
  final List<TextEditingController> _sellTargetsCtrls = [];'''
content = re.sub(pattern_fields, rep_fields, content)

# 2. Add to initState
pattern_init = r'(_tpCtrl\.text = t\.takeProfit\?\.toString\(\) \?\? \'\';)'
rep_init = r'''\1
      if (t.takeProfits != null) {
        _additionalTpCtrls.addAll(t.takeProfits!.map((v) => TextEditingController(text: v.toString())));
      }
      if (t.buyTargets != null) {
        _buyTargetsCtrls.addAll(t.buyTargets!.map((v) => TextEditingController(text: v.toString())));
      }
      if (t.sellTargets != null) {
        _sellTargetsCtrls.addAll(t.sellTargets!.map((v) => TextEditingController(text: v.toString())));
      }'''
content = re.sub(pattern_init, rep_init, content)

# 3. Add to dispose
pattern_dispose = r'(_tpCtrl\.removeListener\(_calculatePnL\);)'
rep_dispose = r'''\1
    for (var c in _additionalTpCtrls) c.dispose();
    for (var c in _buyTargetsCtrls) c.dispose();
    for (var c in _sellTargetsCtrls) c.dispose();'''
content = re.sub(pattern_dispose, rep_dispose, content)

# 4. Save logic
pattern_save = r'(double\? sl = double\.tryParse\(_slCtrl\.text\);\s*double\? tp = double\.tryParse\(_tpCtrl\.text\);)'
rep_save = r'''\1
                List<double> addTps = _additionalTpCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();
                List<double> buyTgts = _buyTargetsCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();
                List<double> sellTgts = _sellTargetsCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();
'''
content = re.sub(pattern_save, rep_save, content)

# 5. Add to TradeModel
pattern_model = r'(stopLoss: sl,\s*takeProfit: tp,)'
rep_model = r'''\1
                        takeProfits: addTps.isNotEmpty ? addTps : null,
                        buyTargets: buyTgts.isNotEmpty ? buyTgts : null,
                        sellTargets: sellTgts.isNotEmpty ? sellTgts : null,'''
content = re.sub(pattern_model, rep_model, content)

# 6. UI Update
pattern_ui = r'(_buildField\(\'Take Profit \(TP\)\', _tpCtrl, half: true, isNum: true\),)'
rep_ui = r'''if (_selectedMarket == 'Futures') ...[
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
                         label: const Text('İkinci TP Ekle', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                       ),
                     ),
                   ],
                   if (_selectedMarket == 'Spot') ...[
                     _buildField('Alım TP-1 (Varsayılan)', _tpCtrl, half: true, isNum: true),
                     for (int i = 0; i < _buyTargetsCtrls.length; i++)
                       _buildField('Alım TP-${i + 2}', _buyTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _buyTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                         label: const Text('Alım Hedefi Ekle', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                       ),
                     ),
                     for (int i = 0; i < _sellTargetsCtrls.length; i++)
                       _buildField('Satış TP-${i + 1}', _sellTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _sellTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.orangeAccent),
                         label: const Text('Satış Hedefi Ekle', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                       ),
                     ),
                   ],'''
content = re.sub(pattern_ui, rep_ui, content)


# 7. Update cell UI helper function
# Let's insert `_buildTpCell` at the class level of `_DailyTradeJournalScreenState`
pattern_helper = r'(class _DailyTradeJournalScreenState extends ConsumerState<DailyTradeJournalScreen> \{)'
rep_helper = r'''\1
  Widget _buildTpCell(TradeModel t) {
    if (t.market == 'Spot') {
      List<String> lines = [];
      if (t.takeProfit != null) lines.add('⬇ Alım 1: ${t.takeProfit}');
      if (t.buyTargets != null && t.buyTargets!.isNotEmpty) {
        for (int i = 0; i < t.buyTargets!.length; i++) {
           lines.add('⬇ Alım ${i+2}: ${t.buyTargets![i]}');
        }
      }
      if (t.sellTargets != null && t.sellTargets!.isNotEmpty) {
        for (int i = 0; i < t.sellTargets!.length; i++) {
           lines.add('⬆ Satış ${i+1}: ${t.sellTargets![i]}');
        }
      }
      if (lines.isEmpty) return const Text('-');
      return Text(lines.join('\n'), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.amberAccent));
    } else {
      List<String> tps = [];
      if (t.takeProfit != null) tps.add('TP-1: ${t.takeProfit}');
      if (t.takeProfits != null) {
        for (int i = 0; i < t.takeProfits!.length; i++) {
          tps.add('TP-${i + 2}: ${t.takeProfits![i]}');
        }
      }
      if (tps.isEmpty) return const Text('-');
      return Text(tps.join('\n'), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.greenAccent));
    }
  }
'''
content = re.sub(pattern_helper, rep_helper, content)


# 8. Replace usage
pattern_cell = r'DataCell\(Text\(t\.takeProfit != null \? \'\$\{t\.takeProfit\}\' \: \'-\'\)\),'
rep_cell = r'''DataCell(_buildTpCell(t)),'''
content = re.sub(pattern_cell, rep_cell, content)


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
