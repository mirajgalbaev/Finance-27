with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

balance = 0
found_class = False
for i, line in enumerate(lines):
    if 'class _DailyPlanTabState' in line:
        found_class = True
    
    # Simple brace counting
    balance += line.count('{')
    balance -= line.count('}')
    
    if found_class and balance == 0:
        print(f"Class closed at line {i+1}")
        print(f"Brace balance reached zero. Context:")
        for j in range(max(0, i-5), min(len(lines), i+6)):
            marker = ">>>" if j == i else "   "
            print(f"{marker} {j+1}: {lines[j].strip()}")
        # Check if there's code after it that shouldn't be
        code_after = "".join(lines[i+1:]).strip()
        if code_after:
            print("WARNING: Code exists after class closure!")
        break
