import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r"ProviderScope\(\s*parent: ProviderScope\.containerOf\(context\),\s*child: Container\(\s*width: MediaQuery\.of\(context\)\.size\.width < 800 \? 800 : MediaQuery\.of\(context\)\.size\.width,\s*child: contentWidget,\s*\),\s*\)"

replacement = """ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF0F172A),
            ),
            home: Material(
              color: const Color(0xFF0F172A),
              child: Container(
                width: MediaQuery.of(context).size.width < 800 ? 800 : MediaQuery.of(context).size.width,
                child: contentWidget,
              ),
            ),
          ),
        )"""

new_text = re.sub(pattern, replacement, text)

if text != new_text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Fixed MaterialLocalizations inside analytics_screen.dart!")
else:
    print("Could not match the pattern.")
