import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove the note_add button
btn_to_remove = '''      IconButton(
        icon: const Icon(Icons.note_add, color: Colors.greenAccent),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(AppStrings.get(ref, 'daily_notes') ?? 'Günlük Notlar', style: const TextStyle(color: Colors.white)),
              content: TextField(
                controller: _noteController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.get(ref, 'enter_notes_here') ?? 'Notlarınızı buraya yazın...',
                  hintStyle: const TextStyle(color: Colors.white54),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL', style: const TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: () { _saveNotes(); Navigator.pop(ctx); },
                  child: Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET'),
                )
              ]
            )
          );
        }
      ),'''
content = content.replace(btn_to_remove, "")

# 2. Wrap _buildExchangeBlock in Screenshot
block_original = '''            return _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale);'''
block_new = '''            return Screenshot(
              controller: _screenshotControllers[exchange]!,
              child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
            );'''
content = content.replace(block_original, block_new)

# 3. Fix _exportScreenshot
export_method_orig_pattern = r"  Future<void> _exportScreenshot\(String exchange\) async \{.*?    \} catch \(e\) \{.*?    \}\n  \}"
export_method_new = '''  Future<void> _exportScreenshot(String exchange) async {
    try {
      final controller = _screenshotControllers[exchange];
      if (controller == null) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'Dışa aktarılıyor, lütfen bekleyin...'), duration: const Duration(seconds: 2)));

      // delay to ensure snackbar doesn't block the UI thread during capture
      await Future.delayed(const Duration(milliseconds: 300));
      
      final Uint8List? imageBytes = await controller.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
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
  }'''

content = re.sub(export_method_orig_pattern, export_method_new, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Fixed UI and export")
