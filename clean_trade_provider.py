import os
import re

path1 = 'c:/Finance 27/lib/providers/trade_provider.dart'
# I messed up trade_provider.dart by duplicating the fields.
# I will just write a python script to clean out duplicate parameter declarations
# Or even better, just replace the chunks perfectly.

with open(path1, 'r', encoding='utf-8') as f:
    content = f.read()

# Let's remove duplicate declarations.
# Find `List<double>? takeProfits,\n    List<double>? buyTargets,\n    List<double>? sellTargets,` and replace all with empty, then append exactly once per function.
bad_chunk = '''
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,'''
content = content.replace(bad_chunk, '')

bad_chunk_2 = '''
      takeProfits: takeProfits,
      buyTargets: buyTargets,
      sellTargets: sellTargets,'''
content = content.replace(bad_chunk_2, '')

bad_chunk_3 = '''
      takeProfits: takeProfits ?? tr.takeProfits,
      buyTargets: buyTargets ?? tr.buyTargets,
      sellTargets: sellTargets ?? tr.sellTargets,'''
content = content.replace(bad_chunk_3, '')


# Now let's carefully insert ONE iteration per method.
# In `Future<void> addTrade({`
pattern_add = r'(Future<void> addTrade\(\{.*?double\? takeProfit,)'
content = re.sub(pattern_add, r'\1\n    List<double>? takeProfits,\n    List<double>? buyTargets,\n    List<double>? sellTargets,', content, flags=re.DOTALL)

pattern_add_2 = r'(final newTrade = TradeModel\([^;]*?takeProfit: takeProfit,)'
content = re.sub(pattern_add_2, r'\1\n      takeProfits: takeProfits,\n      buyTargets: buyTargets,\n      sellTargets: sellTargets,', content, flags=re.DOTALL)

pattern_edit = r'(Future<void> editTrade\(String id, \{.*?double\? takeProfit,)'
content = re.sub(pattern_edit, r'\1\n    List<double>? takeProfits,\n    List<double>? buyTargets,\n    List<double>? sellTargets,', content, flags=re.DOTALL)

# In `tr = tr.copyWith(` inside editTrade. Wait, `TraderNotifier` doesn't have `tr` getter, it was `t.copyWith` maybe?
# The original code probably was `final updated = existingTrade.copyWith(...)` or `final t = state[index]; t.copyWith(...)`
# Let's see how it was written originally! I will just use regex to find where `takeProfit: takeProfit,` is.
# The error `The getter 'tr' isn't defined for the class 'TradeNotifier'` happened because I wrote `takeProfits ?? tr.takeProfits`.
# The existing trade variable name must not be `tr`.
# Let's see what the TradeNotifier uses for it in editTrade.
