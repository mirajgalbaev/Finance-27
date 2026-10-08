import re

with open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the inner rows with FittedBox
content = content.replace('''                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'total_closed'), '', Colors.white),
                            _buildStatBox(AppStrings.get(ref, 'winning_trades'), '', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'loser_upper') ?? 'KAYBEDEN', '', Colors.redAccent),
                          ],
                        ),''', '''                        FittedBox(fit: BoxFit.scaleDown, child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'total_closed'), '', Colors.white),
                            _buildStatBox(AppStrings.get(ref, 'winning_trades'), '', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'loser_upper') ?? 'KAYBEDEN', '', Colors.redAccent),
                          ],
                        ))''')

content = content.replace('''                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'money_won'), '+', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'money_lost'), '-', Colors.redAccent),
                          ],
                        ),''', '''                        FittedBox(fit: BoxFit.scaleDown, child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'money_won'), '+', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'money_lost'), '-', Colors.redAccent),
                          ],
                        ))''')

content = content.replace('''                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(' ', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: netPnL >= 0 ? Colors.greenAccent : Colors.redAccent),
                              )
                            ],
                          ),
                        ),''', '''                        FittedBox(fit: BoxFit.scaleDown, child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(' ', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: netPnL >= 0 ? Colors.greenAccent : Colors.redAccent),
                              )
                            ],
                          ),
                        ))''')

with open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done planner_screen")
