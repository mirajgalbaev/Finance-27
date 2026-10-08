import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

start_idx = text.find('class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {')
end_idx = text.find('class SubTaskModel {', start_idx)

replacement = """class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final ScreenshotController _screenshotController = ScreenshotController();
  
  List<DateTime> _globalDates = [DateTime.now()];
  TimeOfDay _globalTime = TimeOfDay.now();
  final TextEditingController _titleCtrl = TextEditingController();
  List<SubTaskModel> _subtasks = [];
  bool _alarmEnabled = false;

  Future<void> _exportScreenshot() async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Raporu İndir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bu savaş raporunu hangi formatta kaydetmek istiyorsunuz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL', style: TextStyle(color: Colors.white54))),
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
             icon: const Icon(Icons.image, size: 18, color: Colors.white),
             label: const Text('PNG Olarak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             onPressed: () => Navigator.pop(ctx, 'PNG'),
          ),
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
             icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
             label: const Text('PDF Olarak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             onPressed: () => Navigator.pop(ctx, 'PDF'),
          ),
        ],
      )
    );

    if (format == null) return;

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes == null) return;

      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (format == 'PNG') {
        final filePath = '${dir.path}\\\\Planner_${DateFormat('yyyyMM').format(_currentMonth)}_$timestamp.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt Başarılı! PNG Dosyası: $filePath'), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
      } else {
        final pdf = pw.Document();
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) => pw.Center(child: pw.Image(image))
          )
        );
        final filePath = '${dir.path}\\\\Planner_${DateFormat('yyyyMM').format(_currentMonth)}_$timestamp.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt Başarılı! PDF Dosyası: $filePath'), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildMonthSelector(ThemeData theme, String locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _currentMonth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() => _currentMonth = DateTime(picked.year, picked.month, 1));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('MM', locale).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMMM', locale).format(_currentMonth).toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: 4)),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy', locale).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTable(ThemeData theme, String title, List<MapEntry<String, List<ReminderModel>>> groups) {
    if (groups.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('$title İçin Kayıtlı Görev Yok.', style: const TextStyle(color: Colors.white54))),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 0, 
              dataRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: SizedBox.shrink()),
                DataColumn(label: SizedBox.shrink()),
                DataColumn(label: SizedBox.shrink()),
                DataColumn(label: SizedBox.shrink()),
              ],
              rows: groups.map((entry) {
                String groupTitle = entry.key;
                List<ReminderModel> items = entry.value;

                return DataRow(cells: [
                  DataCell(Text(items.first.timeText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                  DataCell(SizedBox(
                    width: 250,
                    child: Text(groupTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orangeAccent)),
                  )),
                  DataCell(Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: items.map((item) {
                           String subTitle = item.title.contains(' - ') ? item.title.substring(item.title.indexOf(' - ') + 3) : item.title;
                           if (!item.title.contains(' - ') && items.length == 1) subTitle = 'Ana Görev';
                           
                           return Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               InkWell(
                                 onTap: () {
                                    ref.read(reminderProvider.notifier).toggleCompletionForDate(item.id, item.startDate, !item.isCompleted);
                                 },
                                 child: Container(
                                   margin: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                                   decoration: BoxDecoration(
                                      color: item.isCompleted ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.1),
                                      border: Border.all(color: item.isCompleted ? Colors.green : Colors.redAccent.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(4)
                                   ),
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   child: Row(
                                      children: [
                                         Icon(item.isCompleted ? Icons.check : Icons.close, size: 12, color: item.isCompleted ? Colors.greenAccent : Colors.redAccent),
                                         const SizedBox(width: 4),
                                         Text(item.isCompleted ? 'Tamamlandı' : 'Beklemede', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isCompleted ? Colors.greenAccent : Colors.redAccent))
                                      ]
                                   ),
                                 ),
                               ),
                               Expanded(
                                 child: Text('• $subTitle', style: TextStyle(fontSize: 13, decoration: item.isCompleted ? TextDecoration.lineThrough : null, color: item.isCompleted ? Colors.greenAccent : Colors.white)),
                               ),
                               const SizedBox(width: 8),
                               Text(DateFormat('dd.MM').format(item.startDate), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                             ]
                           );
                      }).toList(),
                    ),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () {
                         setState(() {
                            _titleCtrl.text = groupTitle;
                            _globalDates = items.map((r) => r.startDate).toSet().toList();
                            try {
                              final p = items.first.timeText.split(RegExp(r'[: ]'));
                              int h = int.parse(p[0]); int m = int.parse(p[1]);
                              if (items.first.timeText.toLowerCase().contains('pm') && h < 12) h += 12;
                              if (items.first.timeText.toLowerCase().contains('am') && h == 12) h = 0;
                              _globalTime = TimeOfDay(hour: h, minute: m);
                            } catch(_) {}
                            _subtasks = items.map((r) {
                               String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : '';
                               return SubTaskModel(title: subTitle, dates: [r.startDate], time: TimeOfDay.now());
                            }).where((s) => s.title.isNotEmpty).toList();
                            for (var item in items) ref.read(reminderProvider.notifier).deleteReminder(item.id);
                         });
                      }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () {
                        for (var item in items) ref.read(reminderProvider.notifier).deleteReminder(item.id);
                      }),
                    ]
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildTopForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
               Expanded(
                 child: ElevatedButton.icon(
                   icon: const Icon(Icons.calendar_month),
                   label: Text(_globalDates.length > 1 ? '${_globalDates.length} Gün Seçildi' : DateFormat('dd.MM.yyyy').format(_globalDates.first)),
                   onPressed: () async {
                      final result = await showDialog<List<DateTime>>(
                        context: context,
                        builder: (context) => MultiDateSelectionDialog(initialDates: _globalDates),
                      );
                      if (result != null && result.isNotEmpty) setState(() => _globalDates = result);
                   },
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)),
                 )
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: ElevatedButton.icon(
                   icon: const Icon(Icons.access_time),
                   label: Text(_globalTime.format(context)),
                   onPressed: () async {
                      final result = await showTimePicker(context: context, initialTime: _globalTime);
                      if (result != null) setState(() => _globalTime = result);
                   },
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.withOpacity(0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)),
                 )
               ),
            ]
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: _titleCtrl.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final savedTitles = List<String>.from(Hive.box('settings').get('planner_templates', defaultValue: <String>[]));
                    if (textEditingValue.text.isEmpty) return savedTitles;
                    return savedTitles.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) => _titleCtrl.text = selection,
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    fieldTextEditingController.addListener(() => _titleCtrl.text = fieldTextEditingController.text);
                    if (fieldTextEditingController.text.isEmpty && _titleCtrl.text.isNotEmpty) fieldTextEditingController.text = _titleCtrl.text;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Plan Başlığı / Şablon',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.bookmark, color: Colors.blueAccent),
                      ),
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 250.0,
                                width: MediaQuery.of(context).size.width - 96,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option, style: const TextStyle(color: Colors.white)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                            onPressed: () {
                                              TextEditingController editCtrl = TextEditingController(text: option);
                                              showDialog(context: context, builder: (ctx) => AlertDialog(
                                                backgroundColor: const Color(0xFF1E293B),
                                                title: const Text('Şablonu Düzenle', style: TextStyle(color: Colors.white)),
                                                content: TextField(controller: editCtrl, style: const TextStyle(color: Colors.white)),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
                                                  ElevatedButton(onPressed: () {
                                                    final box = Hive.box('settings');
                                                    List<String> titles = List<String>.from(box.get('planner_templates', defaultValue: <String>[]));
                                                    int idx = titles.indexOf(option);
                                                    if (idx != -1 && editCtrl.text.isNotEmpty) {
                                                      titles[idx] = editCtrl.text.trim();
                                                      box.put('planner_templates', titles);
                                                    }
                                                    Navigator.pop(ctx);
                                                    setState(() {});
                                                  }, child: const Text('KAYDET'))
                                                ]
                                              ));
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                            onPressed: () {
                                              final box = Hive.box('settings');
                                              List<String> titles = List<String>.from(box.get('planner_templates', defaultValue: <String>[]));
                                              titles.remove(option);
                                              box.put('planner_templates', titles);
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.save, color: Colors.blueAccent),
                  tooltip: 'Şablon Ekle',
                  onPressed: () {
                    final title = _titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      final box = Hive.box('settings');
                      List<String> titles = List<String>.from(box.get('planner_templates', defaultValue: <String>[]));
                      if (!titles.contains(title)) {
                        titles.add(title);
                        box.put('planner_templates', titles);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık eklendi!')));
                        setState(() {});
                      }
                    }
                  }
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: _alarmEnabled ? Colors.orangeAccent.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))),
                child: IconButton(
                  icon: Icon(_alarmEnabled ? Icons.notifications_active : Icons.notifications_off, color: _alarmEnabled ? Colors.orangeAccent : Colors.grey),
                  onPressed: () {
                     if (!_alarmEnabled) { try { AudioPlayer().play(AssetSource('dog.ogg')); } catch (_) {} }
                     setState(() => _alarmEnabled = !_alarmEnabled);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._subtasks.asMap().entries.map((entry) {
            int idx = entry.key;
            final subtask = _subtasks[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: subtask.title)..selection = TextSelection.collapsed(offset: subtask.title.length),
                      onChanged: (v) => subtask.title = v, 
                      decoration: InputDecoration(
                        hintText: 'Alt Görev #\${idx + 1}',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        isDense: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: Colors.white),
                    )
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => setState(() => _subtasks.removeAt(idx)),
                  )
                ]
              )
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _subtasks.add(SubTaskModel(title: '', dates: List.from(_globalDates), time: _globalTime))), 
              icon: const Icon(Icons.add), 
              label: const Text('+ Alt Görev Ekle')
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
               final title = _titleCtrl.text.trim();
               if (title.isEmpty) return;
               
               if (_subtasks.isEmpty) {
                  for (var gd in _globalDates) {
                     await ref.read(reminderProvider.notifier).addReminder(title: title, startDate: gd, timeText: _globalTime.format(context), recurrence: 'none');
                  }
               } else {
                  for (var sub in _subtasks) {
                     if (sub.title.trim().isEmpty) continue;
                     for (var gd in _globalDates) {
                        await ref.read(reminderProvider.notifier).addReminder(title: '${title} - ${sub.title}', startDate: gd, timeText: _globalTime.format(context), recurrence: 'none');
                     }
                  }
               }
               setState(() {
                 _titleCtrl.clear();
                 _subtasks.clear();
                 _globalDates = [DateTime.now()];
               });
               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görevler eklendi!'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('KAYIŞLARI BAĞLA VE ATA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localizationProvider).locale.languageCode;
    final allReminders = ref.watch(reminderProvider);

    final monthReminders = allReminders.where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month).toList();

    final Map<String, List<ReminderModel>> groupedByTitle = {};
    for (var r in monthReminders) {
      String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
      groupedByTitle.putIfAbsent(mainTitle, () => []).add(r);
    }

    List<MapEntry<String, List<ReminderModel>>> dailyGroups = [];
    List<MapEntry<String, List<ReminderModel>>> multiDayGroups = [];

    for (var entry in groupedByTitle.entries) {
       var dates = entry.value.map((e) => e.startDate).toSet();
       if (dates.length > 1) {
          multiDayGroups.add(entry);
       } else {
          dailyGroups.add(entry);
       }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               _buildMonthSelector(theme, locale),
               const SizedBox(height: 12),
               _buildTopForm(),
               const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   ElevatedButton.icon(
                     onPressed: _exportScreenshot, 
                     icon: const Icon(Icons.download), 
                     label: const Text('RAPOR ÇIKART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
                   ),
                 ]
               ),
               const SizedBox(height: 24),
               Screenshot(
                  controller: _screenshotController,
                  child: Container(
                     color: const Color(0xFF0F172A),
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           _buildTaskTable(theme, 'GÜNLÜK GÖREVLER', dailyGroups),
                           _buildTaskTable(theme, 'UZUN VADELİ / ÇOKLU GÜN GÖREVLERİ', multiDayGroups),
                        ]
                     )
                  )
               ),
            ]
         )
      )
    );
  }
}
"""

if start_idx != -1 and end_idx != -1:
    new_text = text[:start_idx] + replacement + "\\n" + text[end_idx:]
    with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
        f.write(new_text)
    print("Success")
else:
    print("Failed boundaries")
