import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

start_table = text.find('  Widget _buildDailyPlanTable')
end_table = text.find('  Widget _buildDailyPlanSummary', start_table)

start_dialog = text.find('  void _showDailyDetailDialog')
end_dialog = text.find('class SubTaskModel {', start_dialog)

table_replacement = '''  Widget _buildDailyPlanTable(ThemeData theme, String locale, List<ReminderModel> dayReminders) {
    if (dayReminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('Bugun icin kay?tl? gorev yok.', style: TextStyle(color: Colors.white54))),
      );
    }

    final Map<String, List<ReminderModel>> grouped = {};
    for (var r in dayReminders) {
      String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
      grouped.putIfAbsent(mainTitle, () => []).add(r);
    }

    return StatefulBuilder(
      builder: (context, setTableState) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF334155)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('SAAT', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PLAN', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('GOREVLER', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('AYARLAR', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
              ],
              rows: grouped.entries.map((entry) {
                String groupTitle = entry.key;
                List<ReminderModel> items = entry.value;
                bool isExpanded = _expandedGroups.contains(groupTitle);

                return DataRow(cells: [
                  DataCell(Text(items.first.timeText, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(groupTitle, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (items.length > 1) 
                          InkWell(
                            onTap: () {
                               setTableState(() {
                                 if (isExpanded) _expandedGroups.remove(groupTitle);
                                 else _expandedGroups.add(groupTitle);
                               });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.blueAccent),
                                 const SizedBox(width: 4),
                                 Text(isExpanded ? 'Gizle' : '\ Gorev', style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                              ]
                            )
                          ),
                        const SizedBox(height: 4),
                        ...items.map((item) {
                           if (!isExpanded && items.length > 1 && items.indexOf(item) > 0) return const SizedBox.shrink();
                           String subTitle = item.title.contains(' - ') ? item.title.substring(item.title.indexOf(' - ') + 3) : item.title;
                           if (!item.title.contains(' - ') && items.length == 1) subTitle = 'Ana Gorev';
                           
                           return Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               InkWell(
                                 onTap: () {
                                    ref.read(reminderProvider.notifier).toggleCompletionForDate(item.id, item.startDate, !item.isCompleted);
                                 },
                                 child: Container(
                                   margin: const EdgeInsets.only(right: 6, bottom: 4, top: 4),
                                   decoration: BoxDecoration(
                                      color: item.isCompleted ? Colors.green.withOpacity(0.2) : Colors.transparent,
                                      border: Border.all(color: item.isCompleted ? Colors.green : Colors.grey.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(4)
                                   ),
                                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                   child: Row(
                                      children: [
                                         Icon(item.isCompleted ? Icons.check : Icons.circle_outlined, size: 12, color: item.isCompleted ? Colors.greenAccent : Colors.white54),
                                         const SizedBox(width: 4),
                                         Text(item.isCompleted ? 'Onayland?' : 'Tamamla', style: TextStyle(fontSize: 9, color: item.isCompleted ? Colors.greenAccent : Colors.white54))
                                      ]
                                   ),
                                 ),
                               ),
                               Expanded(
                                 child: Text('• \', style: TextStyle(fontSize: 12, decoration: item.isCompleted ? TextDecoration.lineThrough : null, color: item.isCompleted ? Colors.greenAccent : Colors.white70)),
                               )
                             ]
                           );
                        }),
                      ],
                    ),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddPlanDialog(context, initialGroupTitle: groupTitle, initialGroupItems: items, defaultDate: items.first.startDate)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () {
                        for (var item in items) ref.read(reminderProvider.notifier).deleteReminder(item.id);
                      }),
                    ]
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
'''

dialog_replacement = '''  Future<void> _exportDailyScreenshot(BuildContext context, ScreenshotController controller, DateTime cellDate) async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Gunluk Raporu Indir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bu gunluk savas raporunu hangi formatta kaydetmek istiyorsunuz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('IPTAL', style: TextStyle(color: Colors.white54))),
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
             icon: const Icon(Icons.image, size: 18, color: Colors.white),
             label: const Text('PNG Olarak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             onPressed: () => Navigator.pop(ctx, 'PNG'),
          ),
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
             icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
             label: const Text('PDF Olarak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             onPressed: () => Navigator.pop(ctx, 'PDF'),
          ),
        ],
      )
    );

    if (format == null) return;

    try {
      final Uint8List? imageBytes = await controller.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes == null) return;

      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (format == 'PNG') {
        final filePath = '\\\\\Daily_Planner_\_\.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kay?t Basar?l?! PNG Dosyas?: \'), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
      } else {
        final pdf = pw.Document();
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context pdfContext) => pw.Center(child: pw.Image(image))
          )
        );
        final filePath = '\\\\\Daily_Planner_\_\.pdf';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kay?t Basar?l?! PDF Dosyas?: \'), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kay?t basar?s?z: \'), backgroundColor: Colors.red));
    }
  }

  void _showDailyDetailDialog(BuildContext context, DateTime cellDate) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      final theme = Theme.of(context);
      final ScreenshotController dailyScreenshotController = ScreenshotController();
      return Consumer(builder: (context, consumerRef, child) {
        final reminders = consumerRef.watch(reminderProvider.notifier).getRemindersForDate(cellDate);
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: Text('GUNLUK ROTA: \'), 
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                       Expanded(
                         flex: 2,
                         child: ElevatedButton.icon(
                           onPressed: () => _showAddPlanDialog(context, defaultDate: cellDate), 
                           icon: const Icon(Icons.add), 
                           label: const Text('YENI GOREV ATA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.blueAccent,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 24),
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         flex: 1,
                         child: ElevatedButton.icon(
                           onPressed: () => _exportDailyScreenshot(context, dailyScreenshotController, cellDate), 
                           icon: const Icon(Icons.download), 
                           label: const Text('DISA AKTAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.orange,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 24),
                           ),
                         ),
                       ),
                    ]
                  ),
                  const SizedBox(height: 24),
                  Screenshot(
                    controller: dailyScreenshotController,
                    child: Container(
                      color: const Color(0xFF0F172A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDailyPlanTable(theme, 'tr', reminders),
                          const SizedBox(height: 24),
                          _buildDailyPlanSummary(theme, 'tr', reminders),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }));
  }

  void _showAddPlanDialog(BuildContext context, {DateTime? defaultDate, String? initialGroupTitle, List<ReminderModel>? initialGroupItems}) {
    List<DateTime> globalDates = [defaultDate ?? DateTime.now()];
    TimeOfDay globalTime = TimeOfDay.now();
    TextEditingController titleCtrl = TextEditingController(text: initialGroupTitle ?? '');
    List<SubTaskModel> subtasks = [];
    bool alarmEnabled = false;

    if (initialGroupItems != null && initialGroupItems.isNotEmpty) {
      if (initialGroupItems.first.startDate != null) globalDates = [initialGroupItems.first.startDate];
      try {
        final p = initialGroupItems.first.timeText.split(RegExp(r'[: ]'));
        int h = int.parse(p[0]);
        int m = int.parse(p[1]);
        if (initialGroupItems.first.timeText.toLowerCase().contains('pm') && h < 12) h += 12;
        if (initialGroupItems.first.timeText.toLowerCase().contains('am') && h == 12) h = 0;
        globalTime = TimeOfDay(hour: h, minute: m);
      } catch(_) {}

      subtasks = initialGroupItems.map((r) {
        String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : '';
        return SubTaskModel(title: subTitle, dates: [r.startDate], time: TimeOfDay.now());
      }).where((s) => s.title.isNotEmpty).toList();
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          appBar: AppBar(
            title: const Text('Gorev Planla'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                     Expanded(
                       child: ElevatedButton.icon(
                         icon: const Icon(Icons.calendar_month),
                         label: Text(globalDates.length > 1 ? '\ Gun Secildi' : DateFormat('dd.MM.yyyy').format(globalDates.first)),
                         onPressed: () async {
                            final result = await showDialog<List<DateTime>>(
                              context: context,
                              builder: (context) => MultiDateSelectionDialog(initialDates: globalDates),
                            );
                            if (result != null && result.isNotEmpty) setDialogState(() => globalDates = result);
                         },
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)),
                       )
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: ElevatedButton.icon(
                         icon: const Icon(Icons.access_time),
                         label: Text(globalTime.format(context)),
                         onPressed: () async {
                            final result = await showTimePicker(context: context, initialTime: globalTime);
                            if (result != null) setDialogState(() => globalTime = result);
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
                        initialValue: TextEditingValue(text: titleCtrl.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final savedTitles = List<String>.from(Hive.box('settings').get('planner_templates', defaultValue: <String>[]));
                          if (textEditingValue.text.isEmpty) {
                            return savedTitles;
                          }
                          return savedTitles.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          titleCtrl.text = selection;
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                          fieldTextEditingController.addListener(() {
                            titleCtrl.text = fieldTextEditingController.text;
                          });
                          if (fieldTextEditingController.text.isEmpty && titleCtrl.text.isNotEmpty) {
                            fieldTextEditingController.text = titleCtrl.text;
                          }
                          return TextField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Plan Basl?g? / Sablon',
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
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
                              color: const Color(0xFF1E293B),
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
                                                title: const Text('Sablonu Duzenle', style: TextStyle(color: Colors.white)),
                                                content: TextField(controller: editCtrl, style: const TextStyle(color: Colors.white)),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('IPTAL')),
                                                  ElevatedButton(onPressed: () {
                                                    final box = Hive.box('settings');
                                                    List<String> titles = List<String>.from(box.get('planner_templates', defaultValue: <String>[]));
                                                    int idx = titles.indexOf(option);
                                                    if (idx != -1 && editCtrl.text.isNotEmpty) {
                                                      titles[idx] = editCtrl.text.trim();
                                                      box.put('planner_templates', titles);
                                                    }
                                                    Navigator.pop(ctx);
                                                    setDialogState(() {});
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
                                              setDialogState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                      },
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
                        tooltip: 'Sablon Olarak S?k Kullan?lanlara Ekle',
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          if (title.isNotEmpty) {
                            final box = Hive.box('settings');
                            List<String> titles = List<String>.from(box.get('planner_templates', defaultValue: <String>[]));
                            if (!titles.contains(title)) {
                              titles.add(title);
                              box.put('planner_templates', titles);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Basl?k haf?zaya eklendi!')));
                              setDialogState(() {});
                            }
                          }
                        }
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: alarmEnabled ? Colors.orangeAccent.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))),
                      child: IconButton(
                        icon: Icon(alarmEnabled ? Icons.notifications_active : Icons.notifications_off, color: alarmEnabled ? Colors.orangeAccent : Colors.grey),
                        tooltip: 'Alarm? Ac/Kapat',
                        onPressed: () {
                           if (!alarmEnabled) { try { AudioPlayer().play(AssetSource('dog.ogg')); } catch (_) {} }
                           setDialogState(() => alarmEnabled = !alarmEnabled);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...subtasks.asMap().entries.map((entry) {
                  int idx = entry.key;
                  final subtask = subtasks[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: subtask.title)..selection = TextSelection.collapsed(offset: subtask.title.length),
                            onChanged: (v) => subtask.title = v, 
                            decoration: InputDecoration(
                              hintText: 'Alt Gorev #\',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              isDense: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            )
                          )
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () => setDialogState(() => subtasks.removeAt(idx)),
                        )
                      ]
                    )
                  );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(() => subtasks.add(SubTaskModel(title: '', dates: List.from(globalDates), time: globalTime))), 
                  icon: const Icon(Icons.add), 
                  label: const Text('+ Alt Gorev Ekle')
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                     final title = titleCtrl.text.trim();
                     if (title.isEmpty) return;
                     if (initialGroupItems != null) { for (var r in initialGroupItems) ref.read(reminderProvider.notifier).deleteReminder(r.id); }
                     
                     if (subtasks.isEmpty) {
                        for (var gd in globalDates) {
                           await ref.read(reminderProvider.notifier).addReminder(title: title, startDate: gd, timeText: globalTime.format(context), recurrence: 'none');
                        }
                     } else {
                        for (var sub in subtasks) {
                           if (sub.title.trim().isEmpty) continue;
                           for (var gd in globalDates) {
                              await ref.read(reminderProvider.notifier).addReminder(title: '\ - \', startDate: gd, timeText: globalTime.format(context), recurrence: 'none');
                           }
                        }
                     }
                     
                     if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('KAYISLARI BAGLA VE ATA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
        );
      });
    }));
  }
'''

if start_table != -1 and end_dialog != -1:
    new_text = text[:start_table] + table_replacement + "\n" + dialog_replacement + "\n" + text[end_dialog:]
    with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
        f.write(new_text)
    print("Success replacing planner logic v5")
else:
    print("Failed to find boundaries", start_table, end_dialog)
