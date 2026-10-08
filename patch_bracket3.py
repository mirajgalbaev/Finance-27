import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target_broken3 = '''              const SizedBox(height: 16),
              
              ], // close else block
              if (_selectedMarket == 'Futures') ...['''

replacement_fixed3 = '''              const SizedBox(height: 16),
              
              if (_selectedMarket == 'Futures') ...['''

content = content.replace(target_broken3, replacement_fixed3)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
