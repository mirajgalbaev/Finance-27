import os

path = 'lib/ui/widgets/mt5_calculator_widget.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''        if (_result != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _result!.validationErrors.isNotEmpty ? const Color(0x1A000000) : const Color(0x1A000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _result!.validationErrors.isNotEmpty ? Colors.red : Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result!.validationErrors.isNotEmpty)
                  ..._result!.validationErrors.map((e) => Text('${AppStrings.get(ref, "mt5_error") ?? "Hata:"} $e', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(ref, 'mt5_req_lot') ?? 'Gerekli Lot Hacmi:', style: const TextStyle(color: Colors.white70)),
                      Text(_result!.finalLotSize.toStringAsFixed(2), style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(ref, 'mt5_act_risk') ?? 'Gerçekleşecek Risk:', style: const TextStyle(color: Colors.white70)),
                      Text('\\$${_result!.actualRiskAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(ref, 'mt5_margin') ?? 'Gerekli Teminat (Margin):', style: const TextStyle(color: Colors.white70)),
                      Text('\\$${_result!.requiredMargin.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),'''

replacement = '''  String _translateError(String err, String lang) {
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
  }''' + '''

        if (_result != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _result!.validationErrors.isNotEmpty ? const Color(0x1A000000) : const Color(0x1A000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _result!.validationErrors.isNotEmpty ? Colors.red : Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result!.validationErrors.isNotEmpty)
                  ..._result!.validationErrors.map((e) => Text('${AppStrings.get(ref, "mt5_error") ?? "Hata:"} ${_translateError(e, ref.read(localeProvider))}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.read(localeProvider) == 'tr' ? 'Gerekli Lot Hacmi:' : 'Required Lot Size:', style: const TextStyle(color: Colors.white70)),
                      Text(_result!.finalLotSize.toStringAsFixed(2), style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.read(localeProvider) == 'tr' ? 'Maksimum Zarar (SL):' : 'Max Loss (SL):', style: const TextStyle(color: Colors.white70)),
                      Text('-\\$${_result!.actualRiskAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_result!.potentialProfit != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ref.read(localeProvider) == 'tr' ? 'Beklenen Kâr (TP):' : 'Potential Profit (TP):', style: const TextStyle(color: Colors.white70)),
                        Text('+\\$${_result!.potentialProfit!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(ref, 'mt5_margin') ?? 'Gerekli Teminat (Margin):', style: const TextStyle(color: Colors.white70)),
                      Text('\\$${_result!.requiredMargin.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ],
              ],
            ),
          ),'''

# because of encoding issues, let's just use string split and replace
if "        if (_result != null)" in content:
    parts = content.split("        if (_result != null)", 1)
    if len(parts) == 2:
        # find the end of the widget
        end_idx = parts[1].rfind('      ],')
        if end_idx != -1:
            content = parts[0] + replacement + parts[1][end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
