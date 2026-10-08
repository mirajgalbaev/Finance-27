import re

path = 'lib/ui/screens/planner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_header = '''                              if (dayTrades.any((t) => t.market == 'Spot'))
                                Text('S:${dayTrades.where((t) => t.market == 'Spot').length} ', style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'Futures'))
                                Text('F:${dayTrades.where((t) => t.market == 'Futures').length}', style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),'''

new_header = '''                              if (dayTrades.any((t) => t.market == 'Spot'))
                                Text('S:${dayTrades.where((t) => t.market == 'Spot').length} ', style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'Futures'))
                                Text('F:${dayTrades.where((t) => t.market == 'Futures').length} ', style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'MT5'))
                                Text('M:${dayTrades.where((t) => t.market == 'MT5').length}', style: const TextStyle(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),'''

old_list = '''                                  itemCount: dayTrades.length > 2 ? 2 : dayTrades.length,
                                  itemBuilder: (context, idx) {
                                    final trade = dayTrades[idx];
                                    double pnlAmount = trade.pnlAmount ?? 0;
                                    bool isOpen = trade.exitPrice == null;
                                    bool isWin = pnlAmount >= 0;
                                    String prefix = trade.market == 'Spot' ? 'S' : 'F';'''

new_list = '''                                  itemCount: dayTrades.length,
                                  itemBuilder: (context, idx) {
                                    final trade = dayTrades[idx];
                                    double pnlAmount = trade.pnlAmount ?? 0;
                                    bool isOpen = trade.exitPrice == null;
                                    bool isWin = pnlAmount >= 0;
                                    String prefix = trade.market == 'Spot' ? 'S' : (trade.market == 'MT5' ? 'MT5' : 'F');'''

content = content.replace(old_header, new_header)
content = content.replace(old_list, new_list)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Updated calendar in planner_screen")
