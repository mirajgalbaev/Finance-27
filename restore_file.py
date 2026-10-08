import os

def fix_planner_screen():
    file_path = 'lib/ui/screens/planner_screen.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # We want to identify the sections and rewrite them cleanly.
    # Section 1: Imports to _DailyPlanTab start (lines 1-637) - Usually safe.
    # Section 2: _DailyPlanTabState class - The corrupted part.
    # Section 3: Helper classes (SubTaskModel, MultiDateSelectionDialog)
    # Section 4: _FinancePlanTabInner
    
    # NEW CONTENT FOR _DailyPlanTabState (Reconstructed from our known good data)
    daily_plan_tab_state_content = r'''
class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final ScreenshotController _planScreenshotController = ScreenshotController();
  final Set<String> _expandedGroups = {};

  Future<void> _exportPlanScreenshot() async {
    try {
      final Uint8List? imageBytes = await _planScreenshotController.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
      if (imageBytes == null) return;
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${dir.path}\\Planner_Journal_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt Başarılı! Dosya: $filePath'), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    ref.watch(reminderProvider);
    final reminders = ref.read(reminderProvider.notifier).getRemindersForDate(_selectedDate);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             child: Container(
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _showAddPlanDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('PLANNER SETUP', style: TextStyle(color: Colors.grey, letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.blueAccent, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('Yeni Görev Ekle', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
             ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1))),
                Expanded(
                  child: Center(
                    child: Text(DateFormat('MMMM yyyy', locale).format(_currentMonth).toUpperCase(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1))),
              ],
            ),
          ),
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: _buildCalendarGrid(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Screenshot(
              controller: _planScreenshotController,
              child: Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AYLIK ÇALIŞMA PLANI (${DateFormat('MMMM yyyy', locale).format(_currentMonth).toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ElevatedButton.icon(
                          onPressed: _exportPlanScreenshot,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('PNG Kaydet'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                        ),
                      ]
                    ),
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                         final all = ref.watch(reminderProvider);
                         final monthReminders = all.where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month).toList();
                         monthReminders.sort((a, b) => a.startDate.compareTo(b.startDate));
                         return _buildDailyPlanTable(theme, locale, monthReminders);
                      }
                    ),
                    const SizedBox(height: 24),
                    _buildMonthlyPlanSummary(theme, locale),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = (offset + daysInMonth > 35) ? 42 : 35;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, childAspectRatio: 0.45, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > daysInMonth) return Container(decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white12)));
        
        DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelected = cellDate.day == _selectedDate.day && cellDate.month == _selectedDate.month && cellDate.year == _selectedDate.year;
        final dayReminders = ref.watch(reminderProvider.notifier).getRemindersForDate(cellDate);
        
        final List<String> displayTitles = [];
        final Map<String, String> groupedTimes = {};
        for (var r in dayReminders) {
          String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
          if (!groupedTimes.containsKey(mainTitle)) {
             groupedTimes[mainTitle] = r.timeText;
             displayTitles.add(mainTitle);
          }
        }
        
        return InkWell(
          onTap: () {
            setState(() => _selectedDate = cellDate);
            _showDailyDetailDialog(context, cellDate);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white12),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(day.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.blueAccent : Colors.grey)),
                const SizedBox(height: 4),
                ...displayTitles.take(3).map((title) => Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
                  child: Text(title, style: const TextStyle(fontSize: 8, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                if (displayTitles.length > 3) Text('+${displayTitles.length - 3}', style: const TextStyle(fontSize: 8, color: Colors.blueAccent)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyPlanTable(ThemeData theme, String locale, List<ReminderModel> dayReminders) {
    if (dayReminders.isEmpty) return const Center(child: Text('Görev bulunamadı.', style: TextStyle(color: Colors.white30)));

    final Map<String, List<ReminderModel>> groupedReminders = {};
    for (var r in dayReminders) {
      String title = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
      groupedReminders.putIfAbsent(title, () => []).add(r);
    }

    return StatefulBuilder(
      builder: (context, setTableState) {
        return Container(
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('TARİH')),
                DataColumn(label: Text('SAAT')),
                DataColumn(label: Text('BAŞLIK / NE İŞ')),
                DataColumn(label: Text('GÖREVLER')),
                DataColumn(label: Text('DURUM')),
                DataColumn(label: Text('DÜZENLE')),
                DataColumn(label: Text('SİL')),
              ],
              rows: groupedReminders.keys.map((groupTitle) {
                final items = groupedReminders[groupTitle]!;
                final firstTime = items.isNotEmpty ? items.first.timeText : '';
                final isExpanded = _expandedGroups.contains(groupTitle);
                final isAllCompleted = items.every((r) => r.isCompleted);
                final displayItems = isExpanded ? items : [items.first];

                return DataRow(cells: [
                  DataCell(Text(DateFormat('dd.MM.yyyy').format(items.first.startDate))),
                  DataCell(Text(firstTime)),
                  DataCell(Text(groupTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...displayItems.map((item) {
                           String subTitle = item.title.contains(' - ') ? item.title.substring(item.title.indexOf(' - ') + 3) : item.title;
                           return Text('• $subTitle', style: TextStyle(fontSize: 12, color: item.isCompleted ? Colors.greenAccent : Colors.white70));
                        }),
                        if (items.length > 1 && !isExpanded)
                           TextButton(
                             onPressed: () => setTableState(() => _expandedGroups.add(groupTitle)),
                             child: Text('[+${items.length - 1} Görev Daha]', style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                           )
                        else if (items.length > 1 && isExpanded)
                           TextButton(
                             onPressed: () => setTableState(() => _expandedGroups.remove(groupTitle)),
                             child: const Text('[Gizle]', style: TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                           )
                      ],
                    ),
                  )),
                  DataCell(ElevatedButton(
                    onPressed: () {
                      for (var item in items) {
                        ref.read(reminderProvider.notifier).toggleCompletionForDate(item.id, item.startDate, !isAllCompleted);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllCompleted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      foregroundColor: isAllCompleted ? Colors.greenAccent : Colors.redAccent,
                    ),
                    child: Text(isAllCompleted ? 'TAMAMLANDI' : 'TAMAMLA'),
                  )),
                  DataCell(IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddPlanDialog(context, initialGroupTitle: groupTitle, initialGroupItems: items))),
                  DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () {
                    for (var item in items) ref.read(reminderProvider.notifier).deleteReminder(item.id);
                  })),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyPlanSummary(ThemeData theme, String locale, List<ReminderModel> dayReminders) {
    int total = dayReminders.length;
    int completed = dayReminders.where((r) => r.isCompleted).length;
    double progress = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          const Text('GÜNLÜK ÖZET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('TOPLAM', '$total', Colors.white),
              _buildStatBox('TAMAM', '$completed', Colors.greenAccent),
              _buildStatBox('BEKLEYEN', '${total - completed}', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(progress == 1.0 ? Colors.green : Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildMonthlyPlanSummary(ThemeData theme, String locale) {
    final all = ref.watch(reminderProvider);
    final monthReminders = all.where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month).toList();
    int total = monthReminders.length;
    int completed = monthReminders.where((r) => r.isCompleted).length;
    double progress = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
      child: Column(
        children: [
          Text('AYLIK BAŞARI ÖZETİ (${DateFormat('MMMM yyyy', locale).format(_currentMonth)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('%${(progress * 100).toStringAsFixed(1)} BASARI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: progress == 1.0 ? Colors.greenAccent : Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Column(children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))]);
  }

  void _showDailyDetailDialog(BuildContext context, DateTime cellDate) {
    Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (context) {
      final theme = Theme.of(context);
      return Consumer(builder: (context, consumerRef, child) {
        final reminders = consumerRef.watch(reminderProvider.notifier).getRemindersForDate(cellDate);
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(title: Text('GÜNLÜK ROTA: ${DateFormat('dd.MM.yyyy').format(cellDate)}'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(onPressed: () => _showAddPlanDialog(context, defaultDate: cellDate), icon: const Icon(Icons.add), label: const Text('YENİ GÖREV ATA')),
                  const SizedBox(height: 24),
                  _buildDailyPlanTable(theme, 'tr', reminders),
                  const SizedBox(height: 24),
                  _buildDailyPlanSummary(theme, 'tr', reminders),
                ],
              ),
            ),
          ),
        );
      });
    }));
  }

  void _showAddPlanDialog(BuildContext context, {DateTime? defaultDate, String? initialGroupTitle, List<ReminderModel>? initialGroupItems}) {
    DateTime taskDate = defaultDate ?? DateTime.now();
    TimeOfDay taskTime = TimeOfDay.now();
    TextEditingController titleCtrl = TextEditingController(text: initialGroupTitle ?? '');
    List<SubTaskModel> subtasks = [];
    bool alarmEnabled = false;

    if (initialGroupItems != null) {
      subtasks = initialGroupItems.map((r) {
        String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : r.title;
        return SubTaskModel(title: subTitle, dates: [r.startDate], time: TimeOfDay.now());
      }).toList();
    }

    Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        final savedTitles = Hive.box('settings').get('planner_templates', defaultValue: <String>[]);
        return Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          appBar: AppBar(
            title: const Text('Görev Planla'),
            actions: [
              IconButton(
                icon: Icon(alarmEnabled ? Icons.notifications_active : Icons.notifications_off, color: alarmEnabled ? Colors.orangeAccent : Colors.grey),
                onPressed: () {
                   if (!alarmEnabled) { try { AudioPlayer().play(AssetSource('dog.ogg')); } catch (_) {} }
                   setDialogState(() => alarmEnabled = !alarmEnabled);
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Plan Başlığı')),
                const SizedBox(height: 16),
                ...subtasks.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Row(children: [Expanded(child: TextField(onChanged: (v) => subtasks[idx].title = v, decoration: InputDecoration(labelText: 'Alt Görev ${idx + 1}')))]);
                }),
                TextButton(onPressed: () => setDialogState(() => subtasks.add(SubTaskModel(title: '', dates: [taskDate], time: taskTime))), child: const Text('+ Alt Görev Ekle')),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                     final title = titleCtrl.text.trim();
                     if (title.isEmpty) return;
                     if (initialGroupItems != null) { for (var r in initialGroupItems) ref.read(reminderProvider.notifier).deleteReminder(r.id); }
                     
                     if (subtasks.isEmpty) {
                        await ref.read(reminderProvider.notifier).addReminder(title: title, startDate: taskDate, timeText: taskTime.format(context), recurrence: 'none');
                     } else {
                        for (var sub in subtasks) {
                           await ref.read(reminderProvider.notifier).addReminder(title: '$title - ${sub.title}', startDate: sub.dates.first, timeText: sub.time.format(context), recurrence: 'none');
                        }
                     }
                     
                     // Persist title to memory
                     List<String> titles = List<String>.from(Hive.box('settings').get('planner_templates', defaultValue: <String>[]));
                     if (!titles.contains(title)) { titles.add(title); Hive.box('settings').put('planner_templates', titles); }

                     if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('KAYDET'),
                ),
              ],
            ),
          ),
        );
      });
    }));
  }
}
'''

    # Identify where the broken block starts and ends.
    # Start: class _DailyPlanTabState
    # End: class SubTaskModel (or class _FinancePlanTabInner if SubTaskModel is gone)
    
    start_idx = -1
    for i, line in enumerate(lines):
        if 'class _DailyPlanTabState' in line:
            start_idx = i
            break
            
    if start_idx == -1:
        print("Could not find _DailyPlanTabState start.")
        return

    # Find the FIRST class or function definition after 638 that IS NOT supposed to be inside.
    # Usually class definitions.
    end_idx = -1
    for i in range(start_idx + 1, len(lines)):
        if 'class ' in lines[i] and '_DailyPlanTabState' not in lines[i]:
            # This is where a NEW class starts.
            # But wait, we want to MOVE those classes outside.
            # So we keep going until we find the end of the file or the start of _FinancePlanTabInner.
            pass
            
    # Actually, let's just find where the 'scrambled' part ends.
    # Based on the error log, line 1696 was 'class SubTaskModel'.
    # I'll look for 'class SubTaskModel' or 'class MultiDateSelectionDialog'.
    
    for i in range(start_idx + 1, len(lines)):
        if 'class SubTaskModel' in lines[i] or 'class MultiDateSelectionDialog' in lines[i] or 'class _FinancePlanTabInner' in lines[i]:
            end_idx = i
            break
            
    if end_idx == -1:
        # If not found, maybe they are corrupted too.
        # I'll just replace up to 2600.
        end_idx = len(lines)

    # Reconstruct the ENTIRE file from the known good pieces.
    # Part 1: imports and classes before 638.
    new_lines = lines[:start_idx]
    
    # Part 2: Fixed _DailyPlanTabState.
    new_lines.append(daily_plan_tab_state_content)
    new_lines.append("\n\n")
    
    # Part 3: Restore the OTHER classes cleanly (taken from the existing file if they exist, or redefined).
    # I'll extract them from the remaining lines of the file.
    remaining_content = "".join(lines[end_idx:])
    
    # Ensure remaining_content starts with a clean class definition.
    # If the user wants to "not lose old code", we should try to keep it.
    new_lines.append(remaining_content)
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("File fixed successfully.")

fix_planner_screen()
