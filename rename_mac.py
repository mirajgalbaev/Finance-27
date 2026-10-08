import io
import re
import os

NEW_NAME = "Kundoluk 27"

def replace_in_file(file_path, replacements):
    if not os.path.exists(file_path):
        return
    with io.open(file_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    new_text = text
    for pattern, replacement in replacements:
        new_text = re.sub(pattern, replacement, new_text)
        
    if text != new_text:
        with io.open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f"Updated {file_path}")

replace_in_file('macos/Runner/Info.plist', [
    (r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', rf'\g<1>{NEW_NAME}\g<2>'),
    (r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)', rf'\g<1>{NEW_NAME}\g<2>')
])
