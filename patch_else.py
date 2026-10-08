import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                      onRiskAmountCalculated: (riskAmt) => setState(() => _capCtrl.text = riskAmt.toString()),
                    )
                  else ...['''

replacement = '''                      onRiskAmountCalculated: (riskAmt) => setState(() => _capCtrl.text = riskAmt.toString()),
                    ),
                  if (_selectedMarket != 'MT5') ...['''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
