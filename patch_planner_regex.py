import re

path = 'lib/ui/screens/planner_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace header
header_pattern = r"if \(dayTrades\.any\(\(t\) => t\.market == 'Spot'\)\).*?Text\('S:\$\{dayTrades\.where\(\(t\) => t\.market == 'Spot'\)\.length\} '.*?fontWeight: FontWeight\.bold\)\),.*?if \(dayTrades\.any\(\(t\) => t\.market == 'Futures'\)\).*?Text\('F:\$\{dayTrades\.where\(\(t\) => t\.market == 'Futures'\)\.length\}'.*?fontWeight: FontWeight\.bold\)\),"

new_header = '''if (dayTrades.any((t) => t.market == 'Spot'))
                                Text('S:${dayTrades.where((t) => t.market == 'Spot').length} ', style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'Futures'))
                                Text('F:${dayTrades.where((t) => t.market == 'Futures').length} ', style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'MT5'))
                                Text('MT5:${dayTrades.where((t) => t.market == 'MT5').length}', style: const TextStyle(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),'''

content = re.sub(header_pattern, new_header, content, flags=re.DOTALL)

# Replace list logic
list_pattern = r"itemCount: dayTrades\.length > 2 \? 2 : dayTrades\.length,.*?itemBuilder: \(context, idx\) \{.*?final trade = dayTrades\[idx\];.*?double pnlAmount = trade\.pnlAmount \?\? 0;.*?bool isOpen = trade\.exitPrice == null;.*?bool isWin = pnlAmount >= 0;.*?String prefix = trade\.market == 'Spot' \? 'S' : 'F';"

new_list = '''itemCount: dayTrades.length,
                                  itemBuilder: (context, idx) {
                                    final trade = dayTrades[idx];
                                    double pnlAmount = trade.pnlAmount ?? 0;
                                    bool isOpen = trade.exitPrice == null;
                                    bool isWin = pnlAmount >= 0;
                                    String prefix = trade.market == 'Spot' ? 'S' : (trade.market == 'MT5' ? 'MT5' : 'F');'''

content = re.sub(list_pattern, new_list, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Forced regex update on planner_screen.dart")
