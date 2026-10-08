import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = '''      final tabTrades = trades.where((t) {
        if (_selectedTab == 'Futures') return t.type == 'Long' || t.type == 'Short';
        if (_selectedTab == 'Spot') return t.type == 'Spot';
        if (_selectedTab == 'MT5') return t.type == 'MT5';
        return false;
      }).toList();'''

new_logic = '''      final tabTrades = trades.where((t) => t.market == _selectedTab).toList();'''

content = content.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Synced tabTrades filter logic with build method")
