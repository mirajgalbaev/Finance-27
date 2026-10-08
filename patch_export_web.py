import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
if 'import \'package:flutter/foundation.dart\'' not in content:
    content = "import 'package:flutter/foundation.dart' show kIsWeb;\n" + content
if 'import \'package:universal_html/html.dart\'' not in content:
    content = "import 'package:universal_html/html.dart' as html;\n" + content

# Fix _exportScreenshot
export_method_orig_pattern = r"  Future<void> _exportScreenshot\(String exchange\) async \{.*?    \} catch \(e\) \{.*?    \}\n  \}"
export_method_new = '''  Future<void> _exportScreenshot(String exchange) async {
    try {
      final controller = _screenshotControllers[exchange];
      if (controller == null) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'Dışa aktarılıyor, lütfen bekleyin...'), duration: const Duration(seconds: 2)));

      await Future.delayed(const Duration(milliseconds: 300));
      
      final Uint8List? imageBytes = await controller.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes == null) return;

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = '${exchange}_Journal_$timestamp.png';

      if (kIsWeb) {
        final blob = html.Blob([imageBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
        }
      } else {
        Directory dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası: {path}').replaceAll('{path}', filePath)), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
        }
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
print("SUCCESS: Fixed export for Web")
