with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        balance = 1
        continue
    
    balance += line.count('{')
    balance -= line.count('}')
    
    if 1220 <= i + 1 <= 1240:
        print(f"{i+1}: {balance} | {line.strip()}")
