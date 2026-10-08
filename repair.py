import os

file_path = 'lib/ui/screens/analytics_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Delete lines 441 to 552 (the incorrectly inserted final exportContentWidget = Container(...);)
# Wait, let's verify line contents first to be safe
start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if "final exportContentWidget = Container(" in line:
        start_idx = i
    if "return Scaffold(" in line and start_idx != -1:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    print(f"Deleting from {start_idx} to {end_idx-1}")
    del lines[start_idx:end_idx]

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
