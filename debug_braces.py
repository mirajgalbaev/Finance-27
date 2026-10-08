import sys

with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
for i, line in enumerate(lines):
    b_before = balance
    balance += line.count('{')
    balance -= line.count('}')
    if balance < b_before and balance < 5: # Show closing lines at shallow depth
        print(f"{i+1}: {balance} | {line.strip()}")
    if balance > b_before and balance < 5: # Show opening lines at shallow depth
        print(f"{i+1}: {balance} | {line.strip()}")
    if balance < 0:
        print(f"ERROR: Negative balance at line {i+1}")
        break
