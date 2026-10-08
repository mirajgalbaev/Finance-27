import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

real_start = text.find("  Widget _buildCalendarGrid() {")
real_end = text.find("  void _showPlannerSetupScreen(BuildContext context) {", real_start)

replacement = """  Widget _buildCalendarGrid() {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    
    // weekday is 1 for Mon, 7 for Sun. The image starts on Sunday (offset 0).
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = 35;
    if (offset + daysInMonth > 35) {
      totalCells = 42;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.45, // Much more vertical space for professional larger text
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
        bool isSelected = cellDate.isAtSameMomentAs(_selectedDate);
        final dayReminders = ref.watch(reminderProvider.notifier).getRemindersForDate(cellDate);
        
        // Group by main title to avoid clutter, keep the first time found for that group
        final Map<String, String> groupedTimes = {};
        final List<String> displayTitles = [];
        for (var r in dayReminders) {
          String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
          if (!groupedTimes.containsKey(mainTitle)) {
             groupedTimes[mainTitle] = r.timeText;
             displayTitles.add(mainTitle);
          }
        }
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
            _showPlannerSetupScreen(context);
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
                if (displayTitles.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayTitles.length > 3 ? 3 : displayTitles.length,
                      itemBuilder: (context, idx) {
                        String title = displayTitles[idx];
                        String time = groupedTimes[title] ?? '';
                        return Container(
                           margin: const EdgeInsets.only(bottom: 4),
                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                           decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Text('${idx + 1}. ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                   Expanded(
                                     child: Text(
                                       title,
                                       style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                   ),
                                 ]
                               ),
                               const SizedBox(height: 2),
                               Row(
                                 children: [
                                   const Icon(Icons.access_time, size: 8, color: Colors.grey),
                                   const SizedBox(width: 2),
                                   Text(time, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600)),
                                 ],
                               )
                             ],
                           )
                        );
                      }
                    )
                  ),
                  if (displayTitles.length > 3)
                    Padding(
                       padding: const EdgeInsets.only(top: 2),
                       child: Text('+${displayTitles.length - 3} görev', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )
              ],
            ),
          ),
        );
      },
    );
  }

"""

if real_start != -1 and real_end != -1:
    text = text[:real_start] + replacement + text[real_end:]
    with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'w', 'utf-8') as f:
        f.write(text)
    print("Fixed accurately.")
else:
    print("Could not find the bounds.")
