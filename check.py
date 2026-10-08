import subprocess
import re

def main():
    result = subprocess.run(['dart', 'analyze', 'lib/ui/screens/planner_screen.dart'], capture_output=True, text=True)
    out = result.stdout + result.stderr
    lines = out.split('\n')
    errors = []
    for line in lines:
        if 'error' in line.lower() or 'Expected' in line or 'Expected' in line or 'Can\'t find' in line:
            errors.append(line)
    
    with open('filtered_errors.txt', 'w') as f:
        f.write('\n'.join(errors))
        
if __name__ == '__main__':
    main()
