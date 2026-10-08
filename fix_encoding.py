import glob

files = glob.glob('lib/ui/screens/*.dart')
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    replacements = {
        'Kay?t Basar?l?! PNG Dosyas?: {path}': 'Kayıt Başarılı! PNG Dosyası: {path}',
        'Kay?t basar?s?z: {error}': 'Kayıt başarısız: {error}',
        'Kay?t Basar?l?! PDF Dosyas?: {path}': 'Kayıt Başarılı! PDF Dosyası: {path}'
    }
    
    modified = False
    for k, v in replacements.items():
        if k in content:
            content = content.replace(k, v)
            modified = True
            
    if modified:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print('Updated encoding', f)
