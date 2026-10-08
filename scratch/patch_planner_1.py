planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

p_content = p_content.replace(
    "DataCell(Text(t.pair, style: const TextStyle(fontWeight: FontWeight.bold))),",
    "DataCell(Text(t.pair == 'Belirsiz' ? (AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz') : t.pair, style: const TextStyle(fontWeight: FontWeight.bold))),"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
