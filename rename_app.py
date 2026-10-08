import io
import re
import os

OLD_NAME = "finance_27"
NEW_NAME = "Kundoluk 27"

def replace_in_file(file_path, replacements):
    if not os.path.exists(file_path):
        print(f"Skipped {file_path} (does not exist)")
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
    else:
        print(f"No changes in {file_path}")


# Android
replace_in_file('android/app/src/main/AndroidManifest.xml', [
    (r'android:label="[^"]*"', f'android:label="{NEW_NAME}"')
])

# iOS
replace_in_file('ios/Runner/Info.plist', [
    (r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', rf'\g<1>{NEW_NAME}\g<2>'),
    (r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)', rf'\g<1>{NEW_NAME}\g<2>')
])

# Web index.html
replace_in_file('web/index.html', [
    (r'<title>.*?</title>', f'<title>{NEW_NAME}</title>'),
    (r'content="finance_27"', f'content="{NEW_NAME}"')
])

# Web manifest.json
replace_in_file('web/manifest.json', [
    (r'"name":\s*"[^"]*"', f'"name": "{NEW_NAME}"'),
    (r'"short_name":\s*"[^"]*"', f'"short_name": "{NEW_NAME}"')
])

# Windows main.cpp (Window Title)
replace_in_file('windows/runner/main.cpp', [
    (r'window\.Create\(L"[^"]*"', f'window.Create(L"{NEW_NAME}"')
])

# Windows Runner.rc
replace_in_file('windows/runner/Runner.rc', [
    (r'VALUE "FileDescription", "[^"]*"', f'VALUE "FileDescription", "{NEW_NAME}"'),
    (r'VALUE "ProductName", "[^"]*"', f'VALUE "ProductName", "{NEW_NAME}"')
])

