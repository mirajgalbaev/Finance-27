import codecs
import re

with codecs.open(r'c:\Finance 27\lib\ui\screens\planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

# First, let's remove the mistakenly inserted _buildCalendarGrid from MultiDateSelectionDialog
bad_insertion_start = text.find("Widget _buildCalendarGrid() {", text.find("class MultiDateSelectionDialog"))
if bad_insertion_start != -1:
    # Find the end of this bad insertion (it ends right before `const SizedBox(height: 10),` or `GridView.builder(` of the dialog)
    # The bad insertion is around 90 lines long.
    bad_insertion_end = text.find("              const SizedBox(height: 10),", bad_insertion_start)
    if bad_insertion_end != -1:
        text = text[:bad_insertion_start] + text[bad_insertion_end:]

# Now replace the real _buildCalendarGrid inside _DailyPlanTabState
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
        childAspectRatio: 0.65,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > daysInMonth) {
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2))),
          );
        }
        
        DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelected = cellDate.isAtSameMomentAs(_selectedDate);
        final dayReminders = ref.watch(reminderProvider.notifier).getRemindersForDate(cellDate);
        
        final Set<String> uniqueTitles = {};
        for (var r in dayReminders) {
          String mainTitle = r.title.contains(' - ') ? r.title.split(' - ').first : r.title;
          uniqueTitles.add(mainTitle);
        }
        final displayTitles = uniqueTitles.toList();
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
            _showPlannerSetupScreen(context);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
            ),
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(day.toString(), style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
                if (displayTitles.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayTitles.length > 3 ? 3 : displayTitles.length,
                      itemBuilder: (context, idx) {
                        return Container(
                           margin: const EdgeInsets.only(bottom: 2),
                           padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                           decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2)
                           ),
                           child: Text(
                             displayTitles[idx],
                             style: TextStyle(fontSize: 8, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           )
                        );
                      }
                    )
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
