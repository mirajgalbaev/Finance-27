import sys

with open('c:\\Finance 27\\web\\index.html', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """<style>
  html, body {
    background-color: #0A0E21;
    overscroll-behavior: none;
    touch-action: none;
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    position: fixed;
    overflow: hidden;
  }
</style>"""

import re
content = re.sub(r'<style>[\s\S]*?</style>', replacement, content)

with open('c:\\Finance 27\\web\\index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
