import os
import re

file_path = 'lib/ui/screens/analytics_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. We need to extract the Container inside Screenshot into a builder method.
# Let's find the Screenshot widget in build method.

pattern = r"(child:\s*Screenshot\(\s*controller:\s*_screenshotController,\s*)(child:\s*Container\([\s\S]*?)(,\s*\)\s*,\s*\)\s*,\s*\]\s*,\s*\)\s*,\s*\]\s*,\s*\)\s*,\s*\)\s*;)"
match = re.search(pattern, content)
if match:
    print("Found Screenshot widget!")
    
# Actually, the safest way is to do string replacement.
