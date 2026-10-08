import re

file_path = r'C:\Finance 27\lib\core\localization_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
cancel_count = 0
for line in lines:
    if "'cancel':" in line:
        cancel_count += 1
        # There are 4 languages, so there should be 4 'cancel' keys total.
        # But wait, each language had one, and I added another one for each language.
        # Let's just keep the first one we see per language?
        # Better: keep track of languages.
        pass

# Actually, the easier way is to just do text replacement for the specific block I added:
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace my added cancel keys
content = content.replace("      'cancel': 'Cancel',\n", "")
content = content.replace("      'cancel': 'İptal',\n", "")
content = content.replace("      'cancel': 'Отмена',\n", "")
content = content.replace("      'cancel': 'Жокко чыгаруу',\n", "")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Duplicates removed.")
