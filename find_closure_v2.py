import sys

with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
found_class = False
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        found_class = True
        balance = 1 # Start at 1
        print(f"Class _DailyPlanTabState started at line {i+1}")
        continue
    
    if found_class:
        balance += line.count('{')
        balance -= line.count('}')
        
        if balance <= 0:
            print(f"Brace balance became zero or negative at line {i+1}: {line.strip()}")
            print("Context:")
            for j in range(max(0, i-5), min(len(lines), i+6)):
                print(f"{j+1}: {lines[j].strip()}")
            break
else:
    print("Class never reached zero balance (open until end of file).")
