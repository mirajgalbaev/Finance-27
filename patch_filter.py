import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Old logic in _exportScreenshot:
#       final trades = ref.read(tradeProvider);
#       final currencySymbol = ref.read(currencyProvider) == 'USD' ? '\\$' : 'в‚є';
#       final locale = ref.read(localeProvider);
#       final exchangeTrades = trades.where((t) => t.exchange == exchange).toList();

old_logic = '''      final trades = ref.read(tradeProvider);
      final currencySymbol = ref.read(currencyProvider) == 'USD' ? '\\$' : '₺';
      final locale = ref.read(localeProvider);
      final exchangeTrades = trades.where((t) => t.exchange == exchange).toList();'''

new_logic = '''      final trades = ref.read(tradeProvider);
      final currencySymbol = ref.read(currencyProvider) == 'USD' ? '\\$' : '₺';
      final locale = ref.read(localeProvider);
      
      final tabTrades = trades.where((t) {
        if (_selectedTab == 'Futures') return t.type == 'Long' || t.type == 'Short';
        if (_selectedTab == 'Spot') return t.type == 'Spot';
        if (_selectedTab == 'MT5') return t.type == 'MT5';
        return false;
      }).toList();
      
      final exchangeTrades = tabTrades.where((t) => t.exchange == exchange).toList();'''

content = content.replace(old_logic, new_logic)

# Replace passing `trades` to _buildGlobalGrandTotalSummary with `tabTrades`
old_summary_call = '''                          _buildGlobalGrandTotalSummary(trades, currencySymbol),'''
new_summary_call = '''                          _buildGlobalGrandTotalSummary(tabTrades, currencySymbol),'''

content = content.replace(old_summary_call, new_summary_call)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Export now filters by selected tab")
