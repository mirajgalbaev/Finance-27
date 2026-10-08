import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Revert my wrapper from the map in build method
block_bad = '''            return Screenshot(
              controller: _screenshotControllers[exchange]!,
              child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
            );'''
block_good = '''            return _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale);'''

content = content.replace(block_bad, block_good)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Removed duplicate Screenshot wrapper")
