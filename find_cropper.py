import os
import glob
import re

files = glob.glob('lib/ui/screens/*.dart') + glob.glob('lib/providers/*.dart') + glob.glob('lib/core/*.dart')
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    if "Fotoğraf" in content or "Fotograf" in content or "Foto" in content:
        print('Found cropper in:', f)
