import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the missing bracket before `if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5')`
# It should close the `Wrap`'s children array AND the Wrap itself!
# Wait, let's see how the Wrap was originally structured:
# Wrap(
#   spacing: 16, runSpacing: 16,
#   children: [
#     _buildField(...),
#     if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
#       _buildField('Take Profit (TP-1)'),
#       ...
#     ],
#     if (_selectedMarket == 'Spot') ...[
#       ...
#     ],
#   ]
# ),
# const Divider(),
#
# But the regex `pattern_leverage` replaced from `if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5')` downwards, and injected:
# if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
#   const SizedBox(height: 16),
#   Text(...),
#   Row(...)
# ],
# const Divider()
#
# This means I accidentally put a `Row` and a `Divider` INSIDE the `Wrap`'s children list?
# No! `Divider` is not allowed inside a list spread `...[` unless it's a widget list, but `Wrap` children is a widget list!
# BUT I closed the spread with `]`, then `const Divider(...)` inside the list?!
# No, `const Divider(...)` is followed by `Container(...)`.
# Let's just properly close the `Wrap` before the `if` and reconstruct the whole block cleanly!

# The easiest way to fix this is to find the exact block and replace it.
pattern = r"Wrap\(\s*spacing: 16,\s*runSpacing: 16,\s*children: \[\s*_buildField\([^\n]+\n[^\n]+\n[^\n]+\n[^\n]+\n\s*if \(_selectedMarket == 'Futures' \|\| _selectedMarket == 'MT5'\) \.\.\.\[[\s\S]*?\]\s*\)"
# I'll just write a script to rewrite from `Wrap(` to `_notesCtrl`.
