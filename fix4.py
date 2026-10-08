import sys
import re

with open('c:\\Finance 27\\web\\index.html', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("body {", "html, body {")
content = content.replace('</head>', '  <meta name="theme-color" content="#0A0E21">\n</head>')

with open('c:\\Finance 27\\web\\index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
