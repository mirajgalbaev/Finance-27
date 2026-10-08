import re

file_path = r'C:\Finance 27\lib\core\localization_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will find all keys that I appended and remove the duplicates.
# Actually, the easiest way is to parse line by line.
# A block starts with 'lang': { and ends with }

lines = content.split('\n')
new_lines = []

current_lang = None
seen_keys = set()

for line in lines:
    lang_match = re.match(r"^\s*'([a-z]{2})':\s*\{\s*$", line)
    if lang_match:
        current_lang = lang_match.group(1)
        seen_keys = set()
        new_lines.append(line)
        continue
    
    if current_lang is not None:
        if line.strip() == '},':
            current_lang = None
            new_lines.append(line)
            continue
        
        # Match a key-value pair: 'key': 'value',
        key_match = re.search(r"^\s*'([^']+)':", line)
        if key_match:
            key = key_match.group(1)
            if key in seen_keys:
                print(f"Removed duplicate {key} in {current_lang}")
                continue
            seen_keys.add(key)
    
    new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))

print("All duplicates removed.")
