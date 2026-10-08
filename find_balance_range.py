with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
found_class = False
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        found_class = True
    
    balance += line.count('{')
    balance -= line.count('}')
    
    if 1150 <= i + 1 <= 1300:
        print(f"{i+1}: {balance} | {line.strip()}")
