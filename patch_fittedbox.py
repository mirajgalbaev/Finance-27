import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_tree = '''              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                          _buildGlobalGrandTotalSummary(trades, currencySymbol),
                        ],
                      ),
                    ),
                  ),
                ),
              ),'''

new_tree = '''              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 1080,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                          _buildGlobalGrandTotalSummary(trades, currencySymbol),
                        ],
                      ),
                    ),
                  ),
                ),
              ),'''

content = content.replace(old_tree, new_tree)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Changed to FittedBox to ensure everything is visible in 9:16")
