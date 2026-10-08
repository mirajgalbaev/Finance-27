import re
import glob
import os

files = glob.glob(r'C:\Finance 27\lib\ui\screens\**\*.dart', recursive=True)
for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'DateFormat' in content:
        # Avoid double wrapping if already wrapped
        content = content.replace("AppStrings.getDateFormatLocale(AppStrings.getDateFormatLocale", "AppStrings.getDateFormatLocale")
        
        # DateFormat('...', locale) -> DateFormat('...', AppStrings.getDateFormatLocale(locale))
        content = re.sub(
            r"DateFormat\(([^,]+),\s*locale\)",
            r"DateFormat(\1, AppStrings.getDateFormatLocale(locale))",
            content
        )
        
        # DateFormat('...', localeCode) -> DateFormat('...', AppStrings.getDateFormatLocale(localeCode))
        content = re.sub(
            r"DateFormat\(([^,]+),\s*localeCode\)",
            r"DateFormat(\1, AppStrings.getDateFormatLocale(localeCode))",
            content
        )
        
        # DateFormat.yMMMM(localeCode) -> DateFormat.yMMMM(AppStrings.getDateFormatLocale(localeCode))
        content = re.sub(
            r"DateFormat\.yMMMM\(localeCode\)",
            r"DateFormat.yMMMM(AppStrings.getDateFormatLocale(localeCode))",
            content
        )
        
        # DateFormat.yMMMd(locale) -> DateFormat.yMMMd(AppStrings.getDateFormatLocale(locale))
        content = re.sub(
            r"DateFormat\.yMMMd\(locale\)",
            r"DateFormat.yMMMd(AppStrings.getDateFormatLocale(locale))",
            content
        )
        
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)

print("Fixed DateFormat calls!")
