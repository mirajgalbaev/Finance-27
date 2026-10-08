import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

start_idx = text.find('class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {')
end_idx = text.find('class SubTaskModel {', start_idx)

if start_idx == -1 or end_idx == -1:
    print("Failed to find boundaries.")
    exit(1)

existing_body = text[start_idx:end_idx]

# We need to rename the class inside existing_body
existing_body = existing_body.replace('class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {', 'class _PlannerSetupFullScreenState extends ConsumerState<PlannerSetupFullScreen> {')

# The current _DailyPlanTabState has a Scaffold. It should probably have an AppBar in the Scaffold for the "close" or "back" button, but for now we can just swap the leading container or AppBar.
# Let's add an AppBar to the existing Scaffold in _PlannerSetupFullScreenState:
# "return Scaffold(" -> "return Scaffold(appBar: AppBar(title: const Text('Planner Setup', style: TextStyle(fontWeight: FontWeight.bold)), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),"
existing_body = existing_body.replace('return Scaffold(', "return Scaffold(appBar: AppBar(title: const Text('Planner Setup', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)), centerTitle: true, leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),")

new_daily_plan_state = """
class PlannerSetupFullScreen extends ConsumerStatefulWidget {
  const PlannerSetupFullScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlannerSetupFullScreen> createState() => _PlannerSetupFullScreenState();
}

class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final allReminders = ref.watch(reminderProvider);

    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(24),
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
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(
                     icon: const Icon(Icons.chevron_left),
                     onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
                   ),
                   Text(DateFormat('MMMM yyyy', locale).format(_currentMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                   IconButton(
                     icon: const Icon(Icons.chevron_right),
                     onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
                   ),
                 ],
               ),
               const SizedBox(height: 24),
               GridView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 7, childAspectRatio: 0.9, crossAxisSpacing: 4, mainAxisSpacing: 4,
                 ),
                 itemCount: totalCells,
                 itemBuilder: (context, index) {
                   int day = index - offset + 1;
                   if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                   
                   DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                   bool isSelected = _selectedDate.year == cellDate.year && _selectedDate.month == cellDate.month && _selectedDate.day == cellDate.day;
                   
                   final dayReminders = allReminders.where((r) => r.startDate.year == cellDate.year && r.startDate.month == cellDate.month && r.startDate.day == cellDate.day).toList();
                   int completedCount = dayReminders.where((r) => r.isCompleted).length;

                   return InkWell(
                     borderRadius: BorderRadius.circular(12),
                     onTap: () {
                         setState(() => _selectedDate = cellDate);
                     },
                     child: Container(
                       decoration: BoxDecoration(
                         color: isSelected ? theme.primaryColor : theme.cardColor.withOpacity(0.5),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: isSelected ? theme.primaryColor : Colors.white10),
                       ),
                       child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Text(day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                             if (dayReminders.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('$completedCount / ${dayReminders.length}', style: TextStyle(color: completedCount == dayReminders.length ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                             ]
                          ]
                       )
                     ),
                   );
                 },
               ),
               const SizedBox(height: 24),
               _buildDailySummaryBox(locale, allReminders),
            ]
         )
      )
    );
  }

  Widget _buildDailySummaryBox(String locale, List<ReminderModel> allReminders) {
      final dayReminders = allReminders.where((r) => r.startDate.year == _selectedDate.year && r.startDate.month == _selectedDate.month && r.startDate.day == _selectedDate.day).toList();
      
      if (dayReminders.isEmpty) {
          return Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
             child: const Center(child: Text('Bu güne ait görev yok.', style: TextStyle(color: Colors.white54))),
          );
      }

      int total = dayReminders.length;
      int completed = dayReminders.where((r) => r.isCompleted).length;

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
                  Text('${DateFormat('dd MMMM yyyy', locale).format(_selectedDate)} GÖREVLERİ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ...dayReminders.map((r) {
                      String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : r.title;
                      return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                              children: [
                                  Icon(r.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: r.isCompleted ? Colors.greenAccent : Colors.white30, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(subTitle, style: TextStyle(decoration: r.isCompleted ? TextDecoration.lineThrough : null, color: r.isCompleted ? Colors.greenAccent : Colors.white))),
                                  Text(r.timeText, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ]
                          )
                      );
                  }),
              ]
          )
      );
  }
}
"""

final_text = text[:start_idx] + new_daily_plan_state + "\n\n" + existing_body + "\n" + text[end_idx:]

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
    f.write(final_text)
print("Success")
