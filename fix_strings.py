import os
import re

files = [
    'lib/ui/screens/planner_screen.dart',
    'lib/ui/screens/daily_trade_journal_screen.dart'
]

for file_path in files:
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    snack_png = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\('Kay[^\n]*?PNG[^\n]*?'\),[\s\S]*?\),[\s\S]*?\);"
    snack_png_replacement = """ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png').replaceAll('{path}', filePath)), backgroundColor: Colors.green));"""

    snack_pdf = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\('Kay[^\n]*?PDF[^\n]*?'\),[\s\S]*?\),[\s\S]*?\);"
    snack_pdf_replacement = """ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_pdf').replaceAll('{path}', filePath)), backgroundColor: Colors.green));"""

    content = re.sub(snack_png, snack_png_replacement, content)
    content = re.sub(snack_pdf, snack_pdf_replacement, content)

    # For daily_trade_journal, it has 'Kay+t Ba?ar+l+!'
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("Translations fixed")
