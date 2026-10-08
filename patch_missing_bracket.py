import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                  _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Г–rn: BTC/USDT)', _pairCtrl, half: true),
                  
                  // Market Selector'''

replacement = '''                  _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Г–rn: BTC/USDT)', _pairCtrl, half: true),
                  ],
                  // Market Selector'''

content = content.replace(target, replacement)

# if target wasn't found due to encoding/spaces, let's just insert it by splitting on // Market Selector
if target not in content:
    parts = content.split('                  // Market Selector', 1)
    if len(parts) == 2:
        content = parts[0] + '                  ],\n                  // Market Selector' + parts[1]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
