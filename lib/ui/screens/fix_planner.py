import os
import re

path = 'c:/Finance 27/lib/ui/screens/planner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update cell UI helper function
# Let's insert `_buildTpCell` at the class level of `_PlannerScreenState`
pattern_helper = r'(class _PlannerScreenState extends ConsumerState<PlannerScreen> \{)'
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

# 2. Replace usage
pattern_cell = r'DataCell\(Text\(t\.takeProfit != null \? \'\$\{t\.takeProfit\}\' \: \'-\'\)\),'
rep_cell = r'''DataCell(_buildTpCell(t)),'''
content = re.sub(pattern_cell, rep_cell, content)

# There is also an `_OpenTradesPanel` widget inside planner_screen.dart that has its own DataRow rendering.
# Let's inject into `_OpenTradesPanelState` too.
pattern_helper_2 = r'(class _OpenTradesPanelState extends ConsumerState<_OpenTradesPanel> \{)'
content = re.sub(pattern_helper_2, rep_helper.replace('class _PlannerScreenState extends ConsumerState<PlannerScreen> {', r'\1'), content)


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
