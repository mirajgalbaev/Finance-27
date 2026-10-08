with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
found_class = False
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        found_class = True
        balance = 1 if '{' in line else 0 # Be careful
        continue
    
    if found_class:
        balance += line.count('{')
        balance -= line.count('}')
        if balance == 0:
            print(f"CLASS CLOSED AT LINE {i+1}: {line.strip()}")
            break
