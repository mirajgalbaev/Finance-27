import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"Expanded\(child: _buildField\(AppStrings\.get\(ref, 'auto_pnl_pct'\) \?\? 'Otomatik P&L \(%\)', _pnlPctCtrl, isNum: true, isAutoCompute: true\)\),\s*const SizedBox\(width: 16\),"

replacement = '''if (_selectedMarket != 'MT5') ...[
                      Expanded(child: _buildField(AppStrings.get(ref, 'auto_pnl_pct') ?? 'Otomatik P&L (%)', _pnlPctCtrl, isNum: true, isAutoCompute: true)),
                      const SizedBox(width: 16),
                    ],'''

content = re.sub(pattern, replacement, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
