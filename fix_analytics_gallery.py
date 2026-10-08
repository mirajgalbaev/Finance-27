import os
import glob
import re

files = ['lib/ui/screens/analytics_screen.dart', 'lib/ui/screens/daily_trade_journal_screen.dart']

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    modified = False

    if 'ImageGallerySaver' not in content:
        content = "import 'package:image_gallery_saver/image_gallery_saver.dart';\n" + content
        modified = True

    # We have `final dir = await getTemporaryDirectory();`
    # Let's replace it with:
    new_dir_logic = """Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }"""
    if "final dir = await getTemporaryDirectory();" in content:
        content = content.replace("final dir = await getTemporaryDirectory();", new_dir_logic)
        modified = True

    # For PNGs in these files, they do `await file.writeAsBytes(imageBytes);` then show a snackbar.
    # We should replace the `file.writeAsBytes` block with `ImageGallerySaver.saveImage`
    # Let's just find the whole export function and replace the PNG success logic.
    
    # We can replace: 
    # await file.writeAsBytes(imageBytes);
    # ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kay...
    
    # Let's use simple string replacements
    content = re.sub(
        r"await file\.writeAsBytes\(imageBytes\);\s*if \(mounted\) ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\([^)]*PNG[^\)]*\)[\s\S]*?\)\);",
        r"await ImageGallerySaver.saveFile(filePath);\n        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));",
        content
    )
    
    content = re.sub(
        r"await file\.writeAsBytes\(bytes\);\s*if \(mounted\) ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\([^)]*PDF[^\)]*\)[\s\S]*?\)\);",
        r"await file.writeAsBytes(bytes);\n        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_pdf') ?? 'Dosyalara Kaydedildi!')));",
        content
    )
    
    # For daily_trade_journal:
    content = re.sub(
        r"await file\.writeAsBytes\(imageBytes\);\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\([^)]*PNG[^\)]*\)[\s\S]*?\)\);",
        r"await ImageGallerySaver.saveFile(filePath);\n        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));",
        content
    )
    
    content = re.sub(
        r"await file\.writeAsBytes\(bytes\);\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?SnackBar\([\s\S]*?content: Text\([^)]*PDF[^\)]*\)[\s\S]*?\)\);",
        r"await file.writeAsBytes(bytes);\n        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_pdf') ?? 'Dosyalara Kaydedildi!')));",
        content
    )

    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
    print('Updated', f)
