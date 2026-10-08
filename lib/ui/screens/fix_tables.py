import os
import re

def fix_planner():
    path = 'c:/Finance 27/lib/ui/screens/planner_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix the exchangeTrades mapping
    content = content.replace("rows: exchangeTrades.map((t) {", "rows: exchangeTrades.asMap().entries.map((entry) {\n                        int index = entry.key + 1;\n                        var t = entry.value;")

    # Fix the regex disaster (Malformed block starting with ')borderRadius')
    # Because there could be a duplicated block there. Let's find exactly the corrupted string.
    # The corrupted string from the logs is:
    #                   )borderRadius: BorderRadius.circular(4),
    #                               border: Border.all(color: isOpen ? Colors.orangeAccent.withOpacity(0.3) : (isWin ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)))
    #                            ),
    #                            child: isOpen 
    
    # We should just find the whole tree and replace it. Let's do it by finding the start of the `if (dayTrades.isNotEmpty)` up to `// Removed simple task empty state`.
    # Let's use a very safe regex.
    pattern = r'if \(dayTrades\.isNotEmpty\)(.*?)(?=\s*// Removed simple task empty state)'
    
    clean_replacement = '''if (dayTrades.isNotEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${dayTrades.length} İşlem', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${dayTrades.where((t) => t.exitPrice != null).length}/${dayTrades.length} Kapanmış', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: dayTrades.where((t) => t.exitPrice != null).length == dayTrades.length && dayTrades.isNotEmpty ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (dayTrades.length > 0)
                          Expanded(
                             child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dayTrades.length > 2 ? 2 : dayTrades.length,
                                itemBuilder: (context, idx) {
                                  final trade = dayTrades[idx];
                                  double pnlAmount = trade.pnlAmount ?? 0;
                                  bool isOpen = trade.exitPrice == null;
                                  final currencySymbol = '\\$';
                                  bool isWin = pnlAmount >= 0;

                                  return Container(
                                     margin: const EdgeInsets.only(bottom: 2),
                                     padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                     decoration: BoxDecoration(
                                        color: isOpen ? Colors.orangeAccent.withOpacity(0.1) : (isWin ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: isOpen ? Colors.orangeAccent.withOpacity(0.3) : (isWin ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)))
                                     ),
                                     child: isOpen 
                                       ? const Text('AÇIK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orangeAccent), textAlign: TextAlign.center, maxLines: 1)
                                       : Text(
                                           isWin ? '+\\$${pnlAmount.toStringAsFixed(1)}' : '-\\$${pnlAmount.abs().toStringAsFixed(1)}',
                                           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isWin ? Colors.green : Colors.redAccent),
                                           maxLines: 1,
                                           textAlign: TextAlign.center,
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                  );
                                }
                             )
                          ),
                        if (dayTrades.length > 2)
                          Padding(
                             padding: const EdgeInsets.only(top: 2),
                             child: Text('+${dayTrades.length - 2}', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          )
                      ]
                    )
                  )
              ],
            ),
          ),
        );
      },
    );
  }
'''

    new_content = re.sub(pattern, clean_replacement, content, flags=re.DOTALL)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)

if __name__ == '__main__':
    fix_planner()
