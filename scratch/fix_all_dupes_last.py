import re

file_path = r'C:\Finance 27\lib\core\localization_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
current_lang = None

# First pass: collect the LAST value for each key in each language
lang_keys = {}
for line in lines:
    lang_match = re.match(r"^\s*'([a-z]{2})':\s*\{\s*$", line)
    if lang_match:
        current_lang = lang_match.group(1)
        lang_keys[current_lang] = {}
        continue
    
    if current_lang is not None:
        if line.strip() == '},':
            current_lang = None
            continue
        key_match = re.search(r"^\s*'([^']+)':", line)
        if key_match:
            key = key_match.group(1)
            lang_keys[current_lang][key] = line

# Second pass: construct the file again
new_lines = []
current_lang = None
for line in lines:
    lang_match = re.match(r"^\s*'([a-z]{2})':\s*\{\s*$", line)
    if lang_match:
        current_lang = lang_match.group(1)
        new_lines.append(line)
        # Append all keys for this language
        for k, v in lang_keys[current_lang].items():
            new_lines.append(v)
        continue
    
    if current_lang is not None:
        if line.strip() == '},':
            current_lang = None
            new_lines.append(line)
        # ignore inner lines because we already appended them
        continue
    
    new_lines.append(line)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))

print("Kept last occurrences of all duplicates.")
