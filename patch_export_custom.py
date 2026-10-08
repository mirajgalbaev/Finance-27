import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add necessary import
if 'import \'package:flutter/rendering.dart\';' not in content:
    content = "import 'package:flutter/rendering.dart';\n" + content

# Define our custom capture function pattern
custom_capture_method = '''  Future<Uint8List?> _captureOffScreenWidget(Widget widget) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    
    // ignore: deprecated_member_use
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    
    final RenderView renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        size: const Size(1080, 5000), // Huge height to prevent overflow
        devicePixelRatio: 2.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
'''

# Replace the export method logic
export_method_orig_pattern = r"  Future<void> _exportScreenshot\(String exchange\) async \{.*?    \} catch \(e\) \{.*?    \}\n  \}"
export_method_new = '''  Future<void> _exportScreenshot(String exchange) async {
    try {
      final trades = ref.read(tradeProvider);
      final currencySymbol = ref.read(currencyProvider) == 'USD' ? '\\$' : '₺';
      final locale = ref.read(localeProvider);
      final exchangeTrades = trades.where((t) => t.exchange == exchange).toList();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'Dışa aktarılıyor, lütfen bekleyin...'), duration: const Duration(seconds: 2)));
      await Future.delayed(const Duration(milliseconds: 300));
      
      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1080, 5000)),
            child: Container(
              width: 1080,
              // No height constraint here! Let it grow naturally.
              child: Material(
                color: const Color(0xFF0F172A),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                ),
              ),
            ),
          ),
        ),
      );

      final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
      
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
  }

''' + custom_capture_method

content = re.sub(export_method_orig_pattern, export_method_new, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Patched with custom off-screen capture")
