import os
import glob

files = glob.glob('lib/ui/screens/*.dart')

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    modified = False

    if 'image_gallery_saver.dart' in content:
        content = content.replace("import 'package:image_gallery_saver/image_gallery_saver.dart';", "import 'package:gal/gal.dart';")
        content = content.replace("await ImageGallerySaver.saveFile(filePath);", "await Gal.putImage(filePath);")
        modified = True

    if modified:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print('Updated with gal', f)
