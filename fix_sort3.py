import io

path = 'lib/ui/screens/planner_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix literal \n
text = text.replace(r"\n    displayedTrades.sort((a, b) => b.date.compareTo(a.date));", "\n    displayedTrades.sort((a, b) => b.date.compareTo(a.date));")

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Fixed literal newline")
