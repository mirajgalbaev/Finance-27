import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

replacement = """class SubTaskModel {
  String title;
  List<DateTime> dates;
  SubTaskModel({required this.title, required this.dates});
}

class _PlannerSetupFullScreenState extends ConsumerState<_PlannerSetupFullScreen> {
  List<DateTime> _globalDates = [];
  TimeOfDay _globalTime = TimeOfDay.now();

  final TextEditingController _titleController = TextEditingController();
  List<SubTaskModel> _subTasks = [];

  @override
  void initState() {
    super.initState();
    _globalDates = [widget.selectedDate];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
                  child: Text(AppStrings.get(ref, 'cancel')),
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

  void _showEditGroupDialog(BuildContext context, String groupTitle, List<ReminderModel> groupItems) {
    String newTitle = groupTitle;
    final controller = TextEditingController(text: groupTitle);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Ana Başlığı Düzenle'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Yeni Ana Başlık'),
            onChanged: (value) => newTitle = value,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get(ref, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTitle.isNotEmpty && newTitle != groupTitle) {
                  for (var r in groupItems) {
                    String subTitlePart = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : '';
                    String updatedTitle = subTitlePart.isNotEmpty ? '$newTitle - $subTitlePart' : newTitle;
                    
                    ref.read(reminderProvider.notifier).editReminder(
                      id: r.id,
                      title: updatedTitle,
                      startDate: r.startDate,
                      timeText: r.timeText,
                      recurrence: r.recurrence,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickMultiDates(List<DateTime> initialDates, Function(List<DateTime>) onPicked) async {
    final List<DateTime>? result = await showDialog<List<DateTime>>(
      context: context,
      builder: (context) => MultiDateSelectionDialog(initialDates: initialDates),
    );
    if (result != null && result.isNotEmpty) {
      onPicked(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(reminderProvider); 
    
    final viewDate = _globalDates.isNotEmpty ? _globalDates.first : widget.selectedDate;
    final reminders = ref.read(reminderProvider.notifier).getRemindersForDate(viewDate);
    
    // Group reminders
    Map<String, List<ReminderModel>> groupedReminders = {};
    for (var r in reminders) {
      String groupTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
      if (!groupedReminders.containsKey(groupTitle)) groupedReminders[groupTitle] = [];
      groupedReminders[groupTitle]!.add(r);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner Setup', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            _buildProfessionalDateTimeSelectors(theme),
            const SizedBox(height: 24),
            _buildTitleForm(theme),
            const SizedBox(height: 24),
            _buildSubTasksList(theme),
            
            if (groupedReminders.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Current Plans for ${DateFormat('dd MMM yyyy').format(viewDate)}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: groupedReminders.keys.length,
                  itemBuilder: (context, index) {
                    final groupTitle = groupedReminders.keys.elementAt(index);
                    final groupItems = groupedReminders[groupTitle]!;
                    
                    return ExpansionTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: const Border(),
                      title: Text(groupTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('${groupItems.length} Görev / İlk Saat: ${groupItems.first.timeText}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
                            onPressed: () => _showEditGroupDialog(context, groupTitle, groupItems),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              for(var r in groupItems) {
                                ref.read(reminderProvider.notifier).deleteReminder(r.id);
                              }
                            },
                          ),
                        ],
                      ),
                      children: groupItems.map((r) {
                        String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : r.title;
                        if (subTitle.trim().isEmpty) subTitle = r.title;
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 48, right: 16),
                          visualDensity: VisualDensity.compact,
                          title: Text(subTitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          subtitle: Text(r.timeText, style: const TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                                onPressed: () => _showEditReminderDialog(context, r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(r.id),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
             left: 16.0, right: 16.0, bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom + 16 : 16.0
          ),
          child: ElevatedButton(
            onPressed: _addPlan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_task, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _subTasks.isNotEmpty ? 'TÜMÜNÜ EKLE (${_subTasks.length} Görev)' : 'PLANI EKLE',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalDateTimeSelectors(ThemeData theme) {
    String dateLabel = _globalDates.length == 1
        ? DateFormat('dd MMM yyyy').format(_globalDates.first)
        : '${_globalDates.length} Gün Seçildi';

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickMultiDates(_globalDates, (dates) => setState(() => _globalDates = dates)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _globalTime,
                );
                if (time != null) {
                  setState(() => _globalTime = time);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(
                      _globalTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleForm(ThemeData theme) {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Ana Plan Başlığı',
        hintText: 'Plan ismi girin...',
        filled: true,
        fillColor: theme.cardColor.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
        prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
      ),
      onChanged: (value) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubTasksList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Alt Görevler', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _subTasks.add(SubTaskModel(
                    title: '',
                    dates: List.from(_globalDates),
                  ));
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              label: const Text('GÖREV EKLE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        if (_subTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Alt görev eklemezseniz Ana Plan seçili günlere eklenecektir.', style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 11, fontStyle: FontStyle.italic)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subTasks.length,
            itemBuilder: (context, index) {
              final subTask = _subTasks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Alt Görev #${index + 1}',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => subTask.title = val,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                          onPressed: () => setState(() => _subTasks.removeAt(index)),
                        )
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickMultiDates(subTask.dates, (dates) => setState(() => subTask.dates = dates)),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range, size: 14, color: Colors.blueAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    subTask.dates.length == 1 ? DateFormat('dd MMM').format(subTask.dates.first) : '${subTask.dates.length} Gün',
                                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Removed individual Time picker from sub tasks
                      ],
                    )
                  ],
                ),
              );
            },
          )
      ],
    );
  }

  Future<void> _addPlan() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen Ana Plan Başlığı girin.')));
      return;
    }

    if (_subTasks.isEmpty) {
      if (_globalDates.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tarih seçin.')));
         return;
      }
      for (var date in _globalDates) {
        await ref.read(reminderProvider.notifier).addReminder(
          title: title,
          startDate: date,
          timeText: _globalTime.format(context),
          recurrence: 'none',
        );
      }
    } else {
      // Add subtasks
      for (var sub in _subTasks) {
        if (sub.title.trim().isEmpty) continue;
        if (sub.dates.isEmpty) continue; // Skip subtasks without dates
        for (var date in sub.dates) {
          await ref.read(reminderProvider.notifier).addReminder(
            title: '$title - ${sub.title.trim()}',
            startDate: date,
            timeText: _globalTime.format(context), // use global time
            recurrence: 'none',
          );
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_subTasks.isEmpty ? 'Ana Plan Eklendi!' : 'Alt Görevler Eklendi!'), duration: const Duration(seconds: 2)));
      setState(() {
        _titleController.clear();
        _subTasks.clear();
      });
    }
  }
}

class MultiDateSelectionDialog extends StatefulWidget {
  final List<DateTime> initialDates;
  const MultiDateSelectionDialog({Key? key, required this.initialDates}) : super(key: key);

  @override
  State<MultiDateSelectionDialog> createState() => _MultiDateSelectionDialogState();
}

class _MultiDateSelectionDialogState extends State<MultiDateSelectionDialog> {
  late List<DateTime> _selectedDates;
  late DateTime _currentMonth;
  DateTime? _rangeStart;

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialDates);
    if (_selectedDates.isNotEmpty) {
      _currentMonth = DateTime(_selectedDates.first.year, _selectedDates.first.month, 1);
    } else {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final existingIndex = _selectedDates.indexWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      if (existingIndex >= 0) {
        _selectedDates.removeAt(existingIndex);
      } else {
        _selectedDates.add(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    final theme = Theme.of(context);

    // FIX OVERFLOW via SingleChildScrollView around Column, and properly size AlertDialog
    return AlertDialog(
      title: const Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text('Günleri Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Aralık seçmek için önce ilk güne çift dokunun, sonra bitişe dokunun.', style: TextStyle(fontSize: 11, color: Colors.grey)),
         ]
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.cardColor,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1); _rangeStart = null; })),
                  Text(DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1); _rangeStart = null; })),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 1.0, crossAxisSpacing: 4, mainAxisSpacing: 4,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  int day = index - offset + 1;
                  if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                  
                  DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  bool isSelected = _selectedDates.any((d) => d.year == cellDate.year && d.month == cellDate.month && d.day == cellDate.day);
                  bool isRangeStart = _rangeStart != null && cellDate.year == _rangeStart!.year && cellDate.month == _rangeStart!.month && cellDate.day == _rangeStart!.day;
                  
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (_rangeStart != null) {
                         DateTime start = _rangeStart!.isBefore(cellDate) ? _rangeStart! : cellDate;
                         DateTime end = _rangeStart!.isBefore(cellDate) ? cellDate : _rangeStart!;
                         setState(() {
                            DateTime current = start;
                            while(current.isBefore(end) || current.isAtSameMomentAs(end)) {
                               bool exists = _selectedDates.any((d) => d.year == current.year && d.month == current.month && d.day == current.day);
                               if (!exists) _selectedDates.add(current);
                               current = current.add(const Duration(days: 1));
                            }
                            _rangeStart = null;
                         });
                      } else {
                         _toggleDate(cellDate);
                      }
                    },
                    onDoubleTap: () {
                      setState(() {
                         if (isRangeStart) {
                            _rangeStart = null;
                         } else {
                            _rangeStart = cellDate;
                         }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : (isRangeStart ? Colors.orangeAccent : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? theme.primaryColor : (isRangeStart ? Colors.orangeAccent : Colors.grey.withOpacity(0.2))),
                      ),
                      alignment: Alignment.center,
                      child: Text(day.toString(), style: TextStyle(color: isSelected || isRangeStart ? Colors.white : (theme.textTheme.bodyMedium?.color ?? Colors.white), fontWeight: isSelected || isRangeStart ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedDates), 
          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
          child: const Text('KAYDET')
        ),
      ],
    );
  }
}
"""

start_idx = text.find("class SubTaskModel {")
if start_idx == -1:
    start_idx = text.find("class _PlannerSetupFullScreenState extends ConsumerState<_PlannerSetupFullScreen> {")

end_idx = text.find("class _FinancePlanTabInner extends ConsumerStatefulWidget {")

if start_idx != -1 and end_idx != -1:
    new_text = text[:start_idx] + replacement + "\n\n" + text[end_idx:]
    with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
        f.write(new_text)
    print("Success")
else:
    print("Indices not found")
