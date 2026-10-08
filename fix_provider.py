import os
import re

path = 'c:/Finance 27/lib/providers/trade_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add to addTrade signature
pattern_add = r'(double\? stopLoss,\s*double\? takeProfit,)'
rep_add = r'''\1
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,'''
content = re.sub(pattern_add, rep_add, content)

# Add to addTrade TradeModel creation
pattern_add2 = r'(stopLoss: stopLoss,\s*takeProfit: takeProfit,)'
rep_add2 = r'''\1
      takeProfits: takeProfits,
      buyTargets: buyTargets,
      sellTargets: sellTargets,'''
content = re.sub(pattern_add2, rep_add2, content)

# Add to editTrade signature
pattern_edit = r'(double\? stopLoss,\s*double\? takeProfit,)'
rep_edit = r'''\1
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,'''
content = re.sub(pattern_edit, rep_edit, content)

# Add to editTrade TradeModel copyWith
pattern_edit2 = r'(stopLoss: stopLoss,\s*takeProfit: takeProfit,)'
rep_edit2 = r'''\1
      takeProfits: takeProfits ?? tr.takeProfits,
      buyTargets: buyTargets ?? tr.buyTargets,
      sellTargets: sellTargets ?? tr.sellTargets,'''
content = re.sub(pattern_edit2, rep_edit2, content)


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
