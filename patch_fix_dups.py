import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will find the first `Widget _buildTabButton` and replace everything up to the END of the last `_exportScreenshot`
# Let's find the indices.

idx1 = content.find("Widget _buildTabButton(String label) {")
if idx1 == -1:
    print("Error: Could not find _buildTabButton")
    exit(1)

# The bad part ends after the SECOND `_exportScreenshot`.
# Actually, the original one has `if (format == null) return;`
# So I can search for `pdf.addPage(` and then find the closing brace of that function.
# Let's just find the `Widget _buildExchangeBlock` which is definitely after all these!
idx2 = content.find("Widget _buildExchangeBlock(String exchange")
if idx2 == -1:
    print("Error: Could not find _buildExchangeBlock")
    exit(1)

# Now, `content[:idx1]` is good. `content[idx2:]` is good.
# I just need to put the correct versions of the 5 functions in between!

correct_functions = '''Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.toUpperCase() + ' ' + (AppStrings.get(ref, 'trades_upper') ?? 'İŞLEMLERİ'),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noteConfig = ref.read(dailyNoteProvider.notifier).getNoteForDate(widget.date);
      if (noteConfig != null) {
        _noteController.text = noteConfig.text;
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    ref.read(dailyNoteProvider.notifier).saveNote(widget.date, _noteController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notlar kaydedildi!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _exportScreenshot(String exchange) async {
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

content = content[:idx1] + correct_functions + content[idx2:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Fixed duplicates")
