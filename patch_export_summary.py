import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_widget_capture = '''                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                    ),
                  ),'''

new_widget_capture = '''                  child: Material(
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
                  ),'''

content = content.replace(old_widget_capture, new_widget_capture)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Added Global Summary and Notes to export")
