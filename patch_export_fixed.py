import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the start of the function
start_marker = "Future<void> _exportScreenshot(String exchange) async {"
end_marker = "Widget _buildTabButton(String label) {"

if start_marker in content and end_marker in content:
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    
    new_func = '''Future<void> _exportScreenshot(String exchange) async {
    try {
      final controller = _screenshotControllers[exchange];
      if (controller == null) return;
      
      final trades = ref.read(tradeProvider);
      final currencySymbol = ref.read(currencyProvider) == 'USD' ? '\\$' : '₺';
      final locale = ref.read(localeProvider);
      final exchangeTrades = trades.where((t) => t.exchange == exchange).toList();
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'Dışa aktarılıyor, lütfen bekleyin...'), duration: const Duration(seconds: 2)));

      final widgetToCapture = Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: const Color(0xFF0F172A),
            child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
          ),
        ),
      );

      final Uint8List? imageBytes = await controller.captureFromWidget(widgetToCapture, delay: const Duration(milliseconds: 200), pixelRatio: 2.0);
      if (imageBytes == null) return;

      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final filePath = '${dir.path}/${exchange}_Journal_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası: {path}').replaceAll('{path}', filePath)), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kayıt başarısız: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  '''
    content = content[:start_idx] + new_func + content[end_idx:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: Replaced")
else:
    print("FAILED: Could not find markers")
