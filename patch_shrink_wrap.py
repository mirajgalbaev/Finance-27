import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''            child: Container(
              width: 1080,
              // No height constraint here! Let it grow naturally.
              child: Material('''

new_code = '''            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 1080,
                  child: Material('''

old_code_end = '''                  child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                ),
              ),
            ),
          ),
        ),
      );'''

new_code_end = '''                  child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                ),
              ),
                ),
              ],
            ),
          ),
        ),
      );'''

content = content.replace(old_code, new_code)
content = content.replace(old_code_end, new_code_end)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS")
