import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = "import 'package:finance_27/models/trade_model.dart';"
replacement = "import 'package:finance_27/models/trade_model.dart';\nimport 'package:finance_27/ui/widgets/mt5_calculator_widget.dart';"

if 'mt5_calculator_widget' not in content:
    content = content.replace(target, replacement)
    
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
