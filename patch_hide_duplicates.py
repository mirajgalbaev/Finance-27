import os

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                   _buildField(AppStrings.get(ref, 'margin_amount') ?? 'Maliyet (Margin) \\$', _capCtrl, half: true, isNum: true),
                   _buildField(AppStrings.get(ref, 'entry_price') ?? 'Giriş Fiyatı', _entryCtrl, half: true, isNum: true),
                   _buildField(AppStrings.get(ref, 'exit_price_manual') ?? 'Çıkış Fiyatı (Manuel)', _exitCtrl, half: true, isNum: true),
                   _buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),'''

replacement = '''              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                   if (_selectedMarket != 'MT5') ...[
                     _buildField(AppStrings.get(ref, 'margin_amount') ?? 'Maliyet (Margin) \\$', _capCtrl, half: true, isNum: true),
                     _buildField(AppStrings.get(ref, 'entry_price') ?? 'Giriş Fiyatı', _entryCtrl, half: true, isNum: true),
                     _buildField(AppStrings.get(ref, 'exit_price_manual') ?? 'Çıkış Fiyatı (Manuel)', _exitCtrl, half: true, isNum: true),
                     _buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),
                   ],'''

if target not in content:
    # try with different encoding/spacing
    target2 = "                   _buildField(AppStrings.get(ref, 'margin_amount') ?? 'Maliyet (Margin) \\$', _capCtrl, half: true, isNum: true),"
    replacement2 = "                   if (_selectedMarket != 'MT5') ...[\n" + target2
    
    target3 = "                   _buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),"
    replacement3 = target3 + "\n                   ],"
    
    content = content.replace(target2, replacement2).replace(target3, replacement3)
else:
    content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
