import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# We want to change the `if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[`
# that wraps the `unleveraged_pnl` field to JUST `if (_selectedMarket == 'Futures') ...[`

pattern = r"if \(_selectedMarket == 'Futures' \|\| _selectedMarket == 'MT5'\) \.\.\.\[\s*Container\(\s*padding: const EdgeInsets\.all\(12\),\s*decoration: BoxDecoration\(color: Colors\.black12, borderRadius: BorderRadius\.circular\(8\)\),\s*child: Row\(\s*children: \[\s*Expanded\(child: _buildField\(AppStrings\.get\(ref, 'unleveraged_pnl'\)"

replacement = '''if (_selectedMarket == 'Futures') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(child: _buildField(AppStrings.get(ref, 'unleveraged_pnl')'''

content = re.sub(pattern, replacement, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
