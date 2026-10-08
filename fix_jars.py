import os
import re

jar_file = 'lib/providers/jar_provider.dart'
with open(jar_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace super([])
content = content.replace("super([])", "super(JarType.values.map((type) => JarModel(type: type)).toList())")

with open(jar_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated jar_provider")
