import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove the bad `],` before `if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[` inside the Wrap
content = content.replace('''_buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),
                   ],
                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[''',
'''_buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),
                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[''')

# 2. Let's make sure the `Wrap` is correctly closed at the end of the `Spot` block.
# The original code had:
#                    ], // closes Spot
#                 ] // closes children
#               ), // closes Wrap
# Let's verify what's actually there. My patch_tp.py put:
#                      ),
#                    ],
#                 ]
#               ),
# This is correct.

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
