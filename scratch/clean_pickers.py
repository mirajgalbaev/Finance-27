import re

def cleanup_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # The messy lines are exactly these:
    messy_str_date = """                              cancelText: AppStrings.get(ref, 'cancel'),
                              confirmText: AppStrings.get(ref, 'confirm'),
                              helpText: AppStrings.get(ref, 'select_date') ?? 'Tarih Seçin',
                              locale: ref.read(localeProvider) == 'kg' ? const Locale('ru') : Locale(ref.read(localeProvider)),"""
    
    messy_str_time = """                              cancelText: AppStrings.get(ref, 'cancel'),
                              confirmText: AppStrings.get(ref, 'confirm'),
                              helpText: AppStrings.get(ref, 'select_time') ?? 'Saat Seçin',"""
                              
    # Remove the exact injections.
    # Wait, in the view_file, they had `\n` before them and were indented by 30 spaces.
    # Let's just use regex to remove any line containing cancelText: AppStrings.get(ref, 'cancel')
    # and confirmText: AppStrings.get...
    # and helpText: AppStrings.get...
    # and locale: ref.read(localeProvider)...

    lines = content.split('\n')
    clean_lines = []
    for line in lines:
        if "cancelText: AppStrings.get(ref, 'cancel')" in line: continue
        if "confirmText: AppStrings.get(ref, 'confirm')" in line: continue
        if "helpText: AppStrings.get(" in line: continue
        if "locale: ref.read(localeProvider) == 'kg' ? const Locale('ru') : Locale(ref.read(localeProvider))" in line: continue
        clean_lines.append(line)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(clean_lines))

cleanup_file(r'C:\Finance 27\lib\ui\screens\planner_screen.dart')
cleanup_file(r'C:\Finance 27\lib\ui\screens\goals_screen.dart')
print("Cleaned up dangling parameters.")
