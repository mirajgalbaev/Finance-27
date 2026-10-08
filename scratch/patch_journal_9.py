journal = r'C:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart'
with open(journal, 'r', encoding='utf-8') as f:
    j_content = f.read()

j_content = j_content.replace(
    "child: Text(value),",
    "child: Text(label),"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
