import sys

with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

def check_balance(lines):
    balance = 0
    class_stack = []
    
    for i, line in enumerate(lines):
        line_num = i + 1
        
        # Track class starts
        if 'class ' in line and '{' in line:
            class_name = line.split('class ')[1].split()[0]
            class_stack.append((class_name, balance, line_num))
        elif 'class ' in line:
            # Handle class on next line
            pass
            
        b_before = balance
        balance += line.count('{')
        balance -= line.count('}')
        
        if balance < 0:
            print(f"FATAL: Negative balance at line {line_num}: {line.strip()}")
            return
            
        if balance == 0 and b_before > 0:
            # Something just closed the last open scope
            print(f"Scope closed at line {line_num}: {line.strip()}")
            if class_stack:
                closed_class, start_balance, start_line = class_stack.pop()
                print(f"  Likely closed class {closed_class} (started at line {start_line})")

check_balance(lines)
