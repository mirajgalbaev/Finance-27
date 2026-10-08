import os

journal = r'C:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart'
with open(journal, 'r', encoding='utf-8') as f:
    j_content = f.read()

bad_line = "[(AppStrings.get(ref, 'manual_exit') ?? 'Manuel Çıkış'), (AppStrings.get(ref, 'tp_hit') ?? 'TP Vuruldu'), (AppStrings.get(ref, 'sl_hit') ?? 'SL Vuruldu')].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList()"

good_line = """['Manuel Çıkış', 'TP Vuruldu', 'SL Vuruldu'].map((m) {
                        String label = m;
                        if (m == 'Manuel Çıkış') label = AppStrings.get(ref, 'manual_exit') ?? m;
                        if (m == 'TP Vuruldu') label = AppStrings.get(ref, 'tp_hit') ?? m;
                        if (m == 'SL Vuruldu') label = AppStrings.get(ref, 'sl_hit') ?? m;
                        return DropdownMenuItem(value: m, child: Text(label));
                      }).toList()"""

j_content = j_content.replace(bad_line, good_line)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Fixed dropdown items.")
