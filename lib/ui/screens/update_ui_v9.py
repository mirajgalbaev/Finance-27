import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

start_idx = text.find("class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {")
end_idx = text.find("class _FinancePlanTabInner extends ConsumerStatefulWidget {")

if start_idx == -1 or end_idx == -1:
    print("Could not find boundaries")
    exit(1)

new_daily_state = """class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final allReminders = ref.watch(reminderProvider);

    // Filter by selected current month to display full tables underneath
    final monthReminders = allReminders.where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month).toList();

    // Grouping
    final Map<String, List<ReminderModel>> groupedByTitle = {};
    for (var r in monthReminders) {
      String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
      groupedByTitle.putIfAbsent(mainTitle, () => []).add(r);
    }

    List<ReminderModel> dailyTasks = [];
    List<ReminderModel> multiDayTasks = [];

    for (var entry in groupedByTitle.entries) {
       var dates = entry.value.map((e) => "${e.startDate.year}-${e.startDate.month}-${e.startDate.day}").toSet();
       if (dates.length > 1) {
          multiDayTasks.addAll(entry.value);
       } else {
          dailyTasks.addAll(entry.value);
       }
    }
    
    // Sort chronologically
    dailyTasks.sort((a, b) => a.startDate.compareTo(b.startDate));
    multiDayTasks.sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               ElevatedButton.icon(
                 onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannerSetupFullScreen()));
                 },
                 icon: const Icon(Icons.settings),
                 label: const Text('PLANNER SETUP (TÜMÜNÜ YÖNET)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                 style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
               ),
               const SizedBox(height: 24),
               
               // Finance Plan Style Header
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1))),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MM', locale).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMMM', locale).format(_currentMonth).toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: 4)),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy', locale).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                    ],
                   ),
                   IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1))),
                 ],
               ),
               const SizedBox(height: 8),
               
               // Days of week
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) {
                    return Expanded(
                      child: Container(
                        color: theme.brightness == Brightness.dark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    );
                  }).toList(),
                ),
               const SizedBox(height: 4),

               // Finance Styled Calendar
               _buildFinanceStyleCalendarGrid(allReminders),
               const SizedBox(height: 32),

               // Daily Summary
               _buildDailySummaryBox(locale, monthReminders),
               const SizedBox(height: 32),

               // Tables
               if (dailyTasks.isNotEmpty) ...[
                 _buildSectionTitle('GÜNLÜK GÖREVLER TABLOSU'),
                 const SizedBox(height: 12),
                 _buildTaskDataTable(dailyTasks, locale),
                 const SizedBox(height: 32),
               ],

               if (multiDayTasks.isNotEmpty) ...[
                 _buildSectionTitle('UZUN VADELİ (ÇOKLU GÜN) GÖREVLER TABLOSU'),
                 const SizedBox(height: 12),
                 _buildTaskDataTable(multiDayTasks, locale),
                 const SizedBox(height: 32),
               ],
               
               if (dailyTasks.isEmpty && multiDayTasks.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Bu aya ait görev bulunamadı.', style: TextStyle(color: Colors.white30, fontSize: 16)))),
                  
               const SizedBox(height: 64),
            ]
         )
      )
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ]
    );
  }

  Widget _buildTaskDataTable(List<ReminderModel> tasks, String locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: const [
            DataColumn(label: Text('TARİH')),
            DataColumn(label: Text('SAAT')),
            DataColumn(label: Text('ANA ŞABLON')),
            DataColumn(label: Text('ALT GÖREV')),
            DataColumn(label: Text('DURUM (İŞLEM)')),
            DataColumn(label: Text('DÜZENLE')),
            DataColumn(label: Text('SİL')),
          ],
          rows: tasks.map((t) {
            String displayDate = DateFormat('dd.MM.yyyy', locale).format(t.startDate);
            String mainTitle = t.title.contains(' - ') ? t.title.split(' - ').first : t.title;
            String subTitle = t.title.contains(' - ') ? t.title.substring(t.title.indexOf(' - ') + 3) : '-';

            return DataRow(cells: [
              DataCell(Text(displayDate, style: const TextStyle(color: Colors.white54))),
              DataCell(Text(t.timeText, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
              DataCell(Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 150, child: Text(subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.isCompleted ? Colors.greenAccent : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)))),
              DataCell(
                 InkWell(
                   onTap: () {
                       final updated = ReminderModel(
                          id: t.id,
                          title: t.title,
                          timeText: t.timeText,
                          startDate: t.startDate,
                          recurrence: t.recurrence,
                          isCompleted: !t.isCompleted
                       );
                       ref.read(reminderProvider.notifier).editReminder(
                          id: t.id,
                          title: updated.title,
                          startDate: updated.startDate,
                          timeText: updated.timeText,
                          recurrence: updated.recurrence,
                          isCompleted: updated.isCompleted
                       );
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: t.isCompleted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(6),
                       border: Border.all(color: t.isCompleted ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                     ),
                     child: Text(t.isCompleted ? 'TAMAMLANDI' : 'AÇIK (BEKLİYOR)', style: TextStyle(color: t.isCompleted ? Colors.green : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                   )
                 )
              ),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                   onPressed: () => _showEditReminderDialog(context, t),
                )
              ),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.delete, color: Colors.white30, size: 18),
                   onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(t.id),
                )
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, ReminderModel reminder) {
    String title = reminder.title;
    TimeOfDay selectedTime = TimeOfDay.now();
    try {
      final parts = reminder.timeText.split(RegExp(r'[: ]'));
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (reminder.timeText.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (reminder.timeText.toLowerCase().contains('am') && hour == 12) hour = 0;
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    String recurrence = reminder.recurrence;
    final controller = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Görevi Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: 'Görev Adı'),
                      onChanged: (value) => title = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saat:', style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setDialogState(() => selectedTime = time);
                            }
                          },
                          child: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      ref.read(reminderProvider.notifier).editReminder(
                        id: reminder.id,
                        title: title,
                        startDate: reminder.startDate,
                        timeText: selectedTime.format(context),
                        recurrence: recurrence,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildFinanceStyleCalendarGrid(List<ReminderModel> allReminders) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.6,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > daysInMonth) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.02),
              border: Border.all(color: Colors.grey.withOpacity(0.1))
            ),
          );
        }
        
        DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelected = cellDate.day == _selectedDate.day && cellDate.month == _selectedDate.month && cellDate.year == _selectedDate.year;
        final dayTasks = allReminders.where((t) => t.startDate.year == cellDate.year && t.startDate.month == cellDate.month && t.startDate.day == cellDate.day).toList();
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                       color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                       shape: BoxShape.circle,
                    ),
                    child: Text(day.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 4),
                if (dayTasks.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayTasks.length > 2 ? 2 : dayTasks.length,
                      itemBuilder: (context, idx) {
                        final task = dayTasks[idx];
                        bool isCompleted = task.isCompleted;

                        return Container(
                           margin: const EdgeInsets.only(bottom: 2),
                           padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                           decoration: BoxDecoration(
                              color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3))
                           ),
                           child: Text(
                             isCompleted ? "BİTTİ" : "AÇIK",
                             style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.orangeAccent),
                             textAlign: TextAlign.center,
                             maxLines: 1,
                           )
                        );
                      }
                    )
                  ),
                  if (dayTasks.length > 2)
                    Padding(
                       padding: const EdgeInsets.only(top: 2),
                       child: Text('+${dayTasks.length - 2}', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailySummaryBox(String locale, List<ReminderModel> monthReminders) {
    int total = monthReminders.length;
    int completedCount = monthReminders.where((r) => r.isCompleted).length;
    int pendingCount = total - completedCount;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AYLIK GÖREV İSTATİSTİKLERİ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat('MMMM yyyy', locale).format(_currentMonth), style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox('TOPLAM\\nGÖREV', '$total', Colors.white),
                            _buildStatBox('TAMAMLANAN', '$completedCount', Colors.greenAccent),
                            _buildStatBox('BEKLEYEN', '$pendingCount', Colors.orangeAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: Colors.white12),
                Expanded(
                   flex: 2,
                   child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            Text(total == 0 ? '%0' : '%${((completedCount / total) * 100).toStringAsFixed(1)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            const Text('Tamamlanma Oranı', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                               value: total == 0 ? 0 : (completedCount / total),
                               backgroundColor: Colors.white10,
                               color: _getPerformanceColor(total == 0 ? 0 : completedCount / total),
                               minHeight: 8,
                               borderRadius: BorderRadius.circular(4),
                            )
                         ]
                      )
                   )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double ratio) {
     if (ratio >= 0.8) return Colors.greenAccent;
     if (ratio >= 0.5) return Colors.orangeAccent;
     return Colors.redAccent;
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, height: 1.2)),
      ],
    );
  }
}
"""

final_text = text[:start_idx] + new_daily_state + "\n" + text[end_idx:]

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
    f.write(final_text)
print("Success - V9 migrated")
