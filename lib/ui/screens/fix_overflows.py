import os
import re

directory = r'c:\Finance 27\lib\ui\screens'
files = [f for f in os.listdir(directory) if f.endswith('.dart')]

# We'll use a stack to find matching parentheses for Row(
for file in files:
    path = os.path.join(directory, file)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    idx = 0
    new_content = ""
    while True:
        # Find next Row(
        row_idx = content.find('Row(', idx)
        if row_idx == -1:
            new_content += content[idx:]
            break
        
        # Append everything before Row(
        new_content += content[idx:row_idx]
        
        # Find the matching closing parenthesis
        paren_count = 1
        curr = row_idx + 4
        while curr < len(content) and paren_count > 0:
            if content[curr] == '(':
                paren_count += 1
            elif content[curr] == ')':
                paren_count -= 1
            curr += 1
            
        if paren_count == 0:
            row_block = content[row_idx:curr]
            
            # Check if it contains Expanded, Flexible, Spacer
            has_expanded = bool(re.search(r'\b(Expanded|Flexible|Spacer)\b', row_block))
            has_space_between = 'MainAxisAlignment.spaceBetween' in row_block
            
            if not has_expanded and has_space_between:
                # Safe to replace
                new_block = row_block.replace('Row(', 'Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, ', 1)
                new_block = new_block.replace('mainAxisAlignment: MainAxisAlignment.spaceBetween', 'alignment: WrapAlignment.spaceBetween')
                new_block = new_block.replace('mainAxisSize: MainAxisSize.min,', '')
                new_content += new_block
            else:
                new_content += row_block
            idx = curr
        else:
            # Unmatched parenthesis, should not happen, just append and move on
            new_content += content[idx:row_idx+4]
            idx = row_idx + 4

    if content != new_content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Patched {file}")
