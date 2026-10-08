import re
with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def replacer(match):
    return """Future<void> _exportPlanner() async {
    try {
        final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
        final allReminders = ref.watch(reminderProvider);
        final monthReminders = allReminders
           .where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month)
           .map((r) => ref.read(reminderProvider.notifier).getRemindersForDate(r.startDate).firstWhere((element) => element.id == r.id, orElse: () => r))
           .toList();
        monthReminders.sort((a, b) => a.startDate.compareTo(b.startDate));

        final widgetToCapture = ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: Size(1080, 1920)),
                child: Theme(
                  data: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F172A)),
                  child: Container(
                    width: 1080, height: 1920,
                    color: const Color(0xFF0F172A),
                    child: FittedBox(
                      fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 1080,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                             color: const Color(0xFF0F172A),
                             padding: const EdgeInsets.all(32.0),
                             child: Column(
                                children: [
                                   _buildDailySummaryBox(locale, monthReminders),
                                   const SizedBox(height: 32),
                                   if (monthReminders.isNotEmpty) ...[
                                     _buildSectionTitle((AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GOREVLER TABLOSU')),
                                     const SizedBox(height: 12),
                                     _buildTaskDataTable(ref, monthReminders, locale),
                                     const SizedBox(height: 32),
                                   ],
                                   if (monthReminders.isEmpty)
                                      Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(AppStrings.get(ref, 'no_monthly_tasks') ?? 'Bu aya ait gorev bulunamadi.', style: const TextStyle(color: Colors.white30, fontSize: 16)))),
                                ]
                             )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        );
        final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
        if (imageBytes == null) return;

        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String prefix = "MonthlyPlan";
        String fileName = '${prefix}_${timestamp}.png';

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
                dir = await getApplicationDocumentsDirectory();
            }
            final filePath = '${dir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            await Gal.putImage(filePath);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }"""

pattern = re.compile(r'Future<void> _exportPlanner\(\) async \{.*?\s*if\s*\(mounted\)\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content:\s*Text\(\(AppStrings\.get\(ref,\s*\'export_failed\'\).*?\}\s*\}', re.DOTALL)

new_text = pattern.sub(replacer, text)
print(f'Matches found: {len(pattern.findall(text))}')

with open('lib/ui/screens/planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_text)
