import sys

with open('c:\\Finance 27\\lib\\core\\app_theme.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """    colorScheme: const ColorScheme.light(
      primary: deepBlueAccent,
      secondary: goldPrimary,
      surface: lightSurface,
      background: lightBackground,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),"""

content = content.replace("""    colorScheme: const ColorScheme.light(
      primary: deepBlueAccent,
      secondary: goldPrimary,
      surface: lightSurface,
      background: lightBackground,
    ),""", replacement)

with open('c:\\Finance 27\\lib\\core\\app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
