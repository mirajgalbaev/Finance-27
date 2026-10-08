import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

# 1. Add missing import for DailyNoteModel at the top
if 'import \'package:finance_27/models/daily_note_model.dart\';' not in text:
    text = text.replace("import 'package:finance_27/models/reminder_model.dart';", "import 'package:finance_27/models/reminder_model.dart';\nimport 'package:finance_27/models/daily_note_model.dart';\nimport 'package:hive_flutter/hive_flutter.dart';")

# 2. Add Monthly Progress Bar to _DailyPlanTabState
progress_bar_injection = """
          // Monthly Progress Bar
          Builder(
            builder: (context) {
              int totalTasks = 0;
              int completedTasks = 0;
              final allReminders = ref.read(reminderProvider);
              for (var r in allReminders) {
                if (r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month) {
                   totalTasks++;
                   if (r.isCompleted) completedTasks++;
                }
              }
              double progress = totalTasks == 0 ? 0 : completedTasks / totalTasks;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aylık İlerleme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                        Text('%${(progress * 100).toInt()} Başarı ($completedTasks/$totalTasks Görev)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
"""

if 'Aylık İlerleme' not in text:
    # insert before 'Row(' of 'Days of week'
    days_of_week_start = text.find("          // Days of week")
    if days_of_week_start != -1:
        text = text[:days_of_week_start] + progress_bar_injection + text[days_of_week_start:]

# 3. Replace Notes (Bottom) with persistent _buildDailyNotesSection 
notes_start = text.find("          // Notes (Bottom)")
notes_end = text.find("        ],", notes_start)
if notes_start != -1 and notes_end != -1:
    text = text[:notes_start] + "          _buildDailyNotesSection(theme),\n" + text[notes_end:]

# Add _buildDailyNotesSection method to _DailyPlanTabState if not exists
build_notes_method = """
  Widget _buildDailyNotesSection(ThemeData theme) {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    var noteBox = Hive.box<DailyNoteModel>('dailyNotes');
    var existingNote = noteBox.get(dateKey);
    final _notesController = TextEditingController(text: existingNote?.text ?? '');

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GÜNLÜK NOTLAR (${DateFormat('dd MMM').format(_selectedDate)})', style: const TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 11)),
              TextButton(
                onPressed: () {
                   String text = _notesController.text.trim();
                   if (text.isNotEmpty) {
                      noteBox.put(dateKey, DailyNoteModel(dateKey: dateKey, text: text, updatedAt: DateTime.now()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not kaydedildi!'), duration: Duration(seconds: 1)));
                   } else {
                      noteBox.delete(dateKey);
                   }
                   FocusScope.of(context).unfocus();
                },
                child: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 11)),
              )
            ]
          ),
          const Divider(),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              decoration: InputDecoration(border: InputBorder.none, hintText: '${DateFormat('dd MMM').format(_selectedDate)} için notlarınızı buraya yazın...', hintStyle: const TextStyle(fontSize: 13, color: Colors.grey)),
              style: theme.textTheme.bodyMedium,
            ),
          )
        ],
      ),
    );
  }
"""
if '_buildDailyNotesSection' not in text:
    end_of_daily_plan_state = text.find("  void _showPlannerSetupScreen(BuildContext context) {")
    if end_of_daily_plan_state != -1:
        text = text[:end_of_daily_plan_state] + build_notes_method + "\n" + text[end_of_daily_plan_state:]

# 4. Add Checkbox to Current Plans list inside _PlannerSetupFullScreenState
checkbox_find = """                          contentPadding: const EdgeInsets.only(left: 48, right: 16),
                          visualDensity: VisualDensity.compact,
                          title: Text(subTitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
"""
checkbox_replace = """                          contentPadding: const EdgeInsets.only(left: 32, right: 16),
                          visualDensity: VisualDensity.compact,
                          leading: Checkbox(
                             value: r.isCompleted,
                             activeColor: Colors.greenAccent,
                             checkColor: Colors.black,
                             onChanged: (val) {
                                if (val != null) {
                                  ref.read(reminderProvider.notifier).editReminder(
                                    id: r.id, title: r.title, startDate: r.startDate, timeText: r.timeText, recurrence: r.recurrence, isCompleted: val
                                  );
                                }
                             }
                          ),
                          title: Text(subTitle, style: TextStyle(fontSize: 13, color: r.isCompleted ? Colors.grey : Colors.white70, decoration: r.isCompleted ? TextDecoration.lineThrough : null)),
"""
if 'leading: Checkbox(' not in text:
    text = text.replace(checkbox_find, checkbox_replace)

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
    f.write(text)
print("UI script updated planner successfully.")
