with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        balance = 1 # Hack to start balance from class start
        continue
    
    balance += line.count('{')
    balance -= line.count('}')
    
    if 1150 <= i + 1 <= 1400:
        print(f"{i+1}: {balance} | {line.strip()}")
