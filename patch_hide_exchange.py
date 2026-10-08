import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                  // Exchange Selector
                  SizedBox(
                    width: 260,
                    child: Row('''

replacement = '''                  // Exchange Selector
                  if (_selectedMarket != 'MT5') ...[
                  SizedBox(
                    width: 260,
                    child: Row('''

content = content.replace(target, replacement)

target2 = '''                  _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Г–rn: BTC/USDT)', _pairCtrl, half: true),
                  
                  // Market Selector'''

replacement2 = '''                  _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Г–rn: BTC/USDT)', _pairCtrl, half: true),
                  ],
                  // Market Selector'''

content = content.replace(target2, replacement2)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
