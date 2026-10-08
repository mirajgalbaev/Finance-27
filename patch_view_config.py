import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_config = '''      configuration: ViewConfiguration(
        size: const Size(1080, 5000), // Huge height to prevent overflow
        devicePixelRatio: 2.0,
      ),'''

new_config = '''      configuration: const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(width: 1080, height: 5000),
        physicalConstraints: BoxConstraints.tightFor(width: 1080 * 2.0, height: 5000 * 2.0),
        devicePixelRatio: 2.0,
      ),'''

content = content.replace(old_config, new_config)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Fixed ViewConfiguration for Flutter 3.10+")
