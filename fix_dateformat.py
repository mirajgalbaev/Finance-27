import os

analytics_path = r"C:\Finance 27\lib\ui\screens\analytics_screen.dart"
jar_path = r"C:\Finance 27\lib\ui\screens\jar_detail_screen.dart"
planner_path = r"C:\Finance 27\lib\ui\screens\planner_screen.dart"

def replace_in_file(path, old, new):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace(old, new)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

replace_in_file(analytics_path, "DateFormat('d MMM yyyy', ref.read(localeProvider) ?? 'tr_TR')", "DateFormat('d MMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR'))")
replace_in_file(jar_path, "DateFormat('MMM d, HH:mm', localeCode)", "DateFormat('MMM d, HH:mm', AppStrings.getDateFormatLocale(localeCode))")
replace_in_file(planner_path, "DateFormat('MMMM d, yyyy', locale)", "DateFormat('MMMM d, yyyy', AppStrings.getDateFormatLocale(locale))")

print("Fixed DateFormat locales")
