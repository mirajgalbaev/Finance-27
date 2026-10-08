import re
with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add imports
if 'package:universal_html/html.dart' not in text:
    text = text.replace("import 'dart:io';", "import 'dart:io';\nimport 'package:universal_html/html.dart' as html;\nimport 'package:flutter/foundation.dart';")

def replacer(match):
    filename_expr = match.group(1) # e.g. "DailyTrades_${timestamp}.png"
    
    return f"""
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String fileName = '{filename_expr}';
        
        if (kIsWeb) {{
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute(\"download\", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {{
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }}
        }} else {{
            Directory dir;
            if (Platform.isAndroid) {{
                dir = Directory('/storage/emulated/0/Download');
            }} else {{
                dir = await getApplicationDocumentsDirectory();
            }}
            final filePath = '${{dir.path}}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            await Gal.putImage(filePath);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }}
"""

pattern = re.compile(
    r"Directory dir;\s*if\s*\(Platform\.isAndroid\)\s*\{\s*dir\s*=\s*Directory\('/storage/emulated/0/Download'\);\s*\}\s*else\s*\{\s*dir\s*=\s*await\s*getApplicationDocumentsDirectory\(\);\s*\}\s*String timestamp = DateFormat\('yyyyMMdd_HHmmss'\)\.format\(DateTime\.now\(\)\);\s*final filePath = '\$\{dir\.path\}/(.*?)';\s*final file = File\(filePath\);\s*await file\.writeAsBytes\(imageBytes\);\s*await Gal\.putImage\(filePath\);\s*if\s*\(mounted\)\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content:\s*Text\(AppStrings\.get\(ref,\s*'export_success_png'\)\s*\?\?\s*'Galeriye Kaydedildi!'\)\)\);",
    re.DOTALL
)

new_text = pattern.sub(replacer, text)
print(f'Replaced {text.count("Directory dir;")} occurrences. Found matches: {len(pattern.findall(text))}')

with open('lib/ui/screens/planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_text)
