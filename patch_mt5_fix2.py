import os

path = 'lib/ui/widgets/mt5_calculator_widget.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the incorrectly placed function
bad_func_start = content.find("  String _translateError(String err, String lang) {")
if bad_func_start != -1:
    bad_func_end = content.find("        if (_result != null)", bad_func_start)
    if bad_func_end != -1:
        content = content[:bad_func_start] + content[bad_func_end:]

# Add it at the class level
class_start = content.find("class _MT5CalculatorWidgetState extends ConsumerState<MT5CalculatorWidget> {")
if class_start != -1:
    insert_pos = content.find("\n", class_start) + 1
    func = '''
  String _translateError(String err, String lang) {
    if (lang == 'tr') {
      if (err.contains("Minimum lot exceeds")) return "Seçilen risk için pozisyon boyutu çok küçük (Minimum lot hacmi belirlediğiniz riski aşıyor). Riskinizi veya bakiyenizi artırın.";
      if (err.contains("Entry Price must be > 0")) return "Giriş fiyatı 0'dan büyük olmalı.";
      if (err.contains("Stop Loss must be > 0")) return "Zarar Kes (SL) 0'dan büyük olmalı.";
      if (err.contains("Take Profit must be > 0")) return "Kâr Al (TP) 0'dan büyük olmalı.";
      if (err.contains("Risk must be > 0")) return "Risk 0'dan büyük olmalı.";
      if (err.contains("Balance must be > 0")) return "Bakiye 0'dan büyük olmalı.";
      if (err.contains("Stop Loss must be below Entry")) return "Geçersiz BUY (Alım) işlemi: Stop Loss giriş fiyatının altında olmalı.";
      if (err.contains("Take Profit must be above Entry")) return "Geçersiz BUY (Alım) işlemi: Take Profit giriş fiyatının üstünde olmalı.";
      if (err.contains("Stop Loss must be above Entry")) return "Geçersiz SELL (Satış) işlemi: Stop Loss giriş fiyatının üstünde olmalı.";
      if (err.contains("Take Profit must be below Entry")) return "Geçersiz SELL (Satış) işlemi: Take Profit giriş fiyatının altında olmalı.";
      if (err.contains("Stop Loss is too close")) return "Stop Loss giriş fiyatına çok yakın.";
      if (err.contains("Take Profit is too close")) return "Take Profit giriş fiyatına çok yakın.";
      if (err.contains("Insufficient free margin")) return "Yetersiz bakiye (Teminat yetmiyor).";
    }
    return err;
  }
'''
    content = content[:insert_pos] + func + content[insert_pos:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
