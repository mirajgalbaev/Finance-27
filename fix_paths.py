import glob

files = glob.glob('lib/ui/screens/*.dart')
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    target = "${dir.path}\\\\"
    replacement = "${dir.path}/"
    if target in content:
        content = content.replace(target, replacement)
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print('Updated', f)
