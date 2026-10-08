import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r"Future<void> _exportScreenshot\(Widget contentWidget\) async \{.*?\n\s+void _showFilterModal\(\) \{"

replacement = """Future<void> _exportScreenshot(Widget contentWidget) async {
    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_started') ?? 'Analiz haz?rlan?yor, lutfen bekleyin...'), duration: Duration(seconds: 2)));
      
      final Uint8List? imageBytes = await _screenshotController.captureFromLongWidget(
        ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: contentWidget,
        ),
        context: context,
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 500),
      );
      if (imageBytes == null) return;

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'Analytics_$timestamp.png';

      if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }
      } else {
          Directory dir;
          if (Platform.isAndroid) {
              dir = Directory('/storage/emulated/0/Download');
          } else {
              dir = await getTemporaryDirectory();
          }
          final filePath = '${dir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);
          await Gal.putImage(filePath);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!').replaceAll('{path}', filePath)), backgroundColor: Colors.green));
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterModal() {"""

new_text = re.sub(pattern, replacement, text, flags=re.DOTALL)

if text != new_text:
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Export button fixed successfully!")
else:
    print("Could not match the pattern.")
