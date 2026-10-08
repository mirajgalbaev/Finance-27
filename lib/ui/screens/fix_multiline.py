import os
import re

path1 = 'c:/Finance 27/lib/ui/screens/daily_trade_journal_screen.dart'
path2 = 'c:/Finance 27/lib/ui/screens/planner_screen.dart'

for path in [path1, path2]:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix the literal newline inside the Dart string literals
    content = re.sub(r"join\('\n'\)", r"join('\\n')", content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# The method '_buildTpCell' isn't defined for the class '_FinancePlanTabInnerState'
with open(path2, 'r', encoding='utf-8') as f:
    content2 = f.read()

pattern_helper = r'''  Widget _buildTpCell(TradeModel t) {
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
      return Text(lines.join('\\n'), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.amberAccent));
    } else {
      List<String> tps = [];
      if (t.takeProfit != null) tps.add('TP-1: ${t.takeProfit}');
      if (t.takeProfits != null) {
        for (int i = 0; i < t.takeProfits!.length; i++) {
          tps.add('TP-${i + 2}: ${t.takeProfits![i]}');
        }
      }
      if (tps.isEmpty) return const Text('-');
      return Text(tps.join('\\n'), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.greenAccent));
    }
  }

'''

if "class _FinancePlanTabInnerState" in content2:
    if "_buildTpCell" not in content2.split("class _FinancePlanTabInnerState extends ConsumerState<_FinancePlanTabInner>")[1].split("Widget build")[0]:
        content2 = content2.replace("class _FinancePlanTabInnerState extends ConsumerState<_FinancePlanTabInner> {\n", "class _FinancePlanTabInnerState extends ConsumerState<_FinancePlanTabInner> {\n" + pattern_helper)

with open(path2, 'w', encoding='utf-8') as f:
    f.write(content2)

# Fix GC6690633: No named parameter with the name 'takeProfits' in `daily_trade_journal_screen.dart`
# Let's check what it is
with open(path1, 'r', encoding='utf-8') as f:
    c = f.read()

# Ah! TradeModel doesn't have `takeProfits` parameter in constructor maybe?
# I ran build_runner. But I also had to update the constructor of TradeModel.
# Wait, I did update the `TradeModel` constructor. 
# But wait, `daily_trade_journal_screen.dart(1326,25)`
# It's an issue with the AddTradeDialog state: `daily_trade_journal_screen.dart` uses `t.copyWith` or `TradeModel(...)` which is missing the named parameter? No wait, I added `takeProfits` to TradeModel, did I do it to TradeModel copyWith too? Yes!
# BUT let's verify if `daily_trade_journal_screen.dart` has an old class definition or something else.
# Wait, "No named parameter with the name 'takeProfits'" means the Dart compiler thinks TradeModel doesn't have it!
# Wait, let me check lib/models/trade_model.dart

