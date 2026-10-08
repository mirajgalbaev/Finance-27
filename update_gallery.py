import os
import glob
import re

files = glob.glob('lib/ui/screens/*.dart')

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    modified = False

    if 'ImageGallerySaver' not in content and 'shareXFiles' in content:
        content = "import 'package:image_gallery_saver/image_gallery_saver.dart';\n" + content
        modified = True

    # PDF logic
    # Right now, it's getting getTemporaryDirectory(). We need to change that so PDFs go to public downloads.
    # Actually, we can just save PNGs from temp directory to Gallery, and save PDFs to Downloads directory!
    
    # We have `final dir = await getTemporaryDirectory();`
    # Let's replace it with:
    new_dir_logic = """Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }"""
    content = content.replace("final dir = await getTemporaryDirectory();", new_dir_logic)

    # For PNGs:
    png_pattern = r"if\s*\(mounted\)\s*await\s*Share\.shareXFiles\(\[XFile\(filePath\)\],\s*text:\s*'Exported PNG'\);"
    if re.search(png_pattern, content):
        content = re.sub(png_pattern, "await ImageGallerySaver.saveFile(filePath);\n        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));", content)
        modified = True

    # For PDFs:
    pdf_pattern = r"if\s*\(mounted\)\s*await\s*Share\.shareXFiles\(\[XFile\(filePath\)\],\s*text:\s*'Exported PDF'\);"
    if re.search(pdf_pattern, content):
        content = re.sub(pdf_pattern, "if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_pdf') ?? 'Dosyalara Kaydedildi!')));", content)
        modified = True

    if modified:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print('Updated Gallery Saver', f)
