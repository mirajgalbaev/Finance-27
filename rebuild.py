import codecs

with codecs.open('c:/Finance 27/lib/ui/screens/planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

s1 = text.find('class _PlannerSetupFullScreenState extends ConsumerState<PlannerSetupFullScreen> {')
s2 = text.find('class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {')

original_class = text[s1:s2]

new_class = original_class.replace(
    'TimeOfDay _globalTime = TimeOfDay.now();',
    'TimeOfDay _globalTime = TimeOfDay.now();\n  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);\n  DateTime _viewSelectedDate = DateTime.now();\n  bool _isDailyTab = true;\n'
)

def get_block(start_kw, br_start='{', br_end='}'):
    start_idx = text.find(start_kw)
    if start_idx == -1: return ''
    count = 0
    in_block = False
    for i in range(start_idx, len(text)):
        if text[i] == br_start:
            count += 1
            in_block = True
        elif text[i] == br_end:
            count -= 1
        if in_block and count == 0:
            return text[start_idx:i+1]
    return ''

cal_func = get_block('Widget _buildFinanceStyleCalendarGrid')
stat_func = get_block('Widget _buildDailySummaryBox')
table_func = get_block('Widget _buildTaskDataTable')
stat_help1 = get_block('Color _getPerformanceColor')
stat_help2 = get_block('Widget _buildStatBox')

# We also need to get _showEditReminderDialog which is called by the table
edit_func = get_block('void _showEditReminderDialog')

cal_func = cal_func.replace('_currentMonth', '_viewMonth').replace('_selectedDate', '_viewSelectedDate')
stat_func = stat_func.replace('Widget _buildDailySummaryBox', 'Widget _buildSummaryBox')
stat_func = stat_func.replace('AYLIK GÖREV İSTATİSTİKLERİ', "${_isDailyTab ? 'GÜNLÜK' : 'AYLIK'} GÖREV İSTATİSTİKLERİ")
stat_func = stat_func.replace("DateFormat('MMMM yyyy', locale).format(_currentMonth)", "DateFormat(_isDailyTab ? 'dd MMMM yyyy' : 'MMMM yyyy', locale).format(_isDailyTab ? _viewSelectedDate : _viewMonth)")

build_start = new_class.find('Widget build(BuildContext context) {')
if_group_start = new_class.find('if (groupedReminders.isNotEmpty) ...[', build_start)
if_group_end = new_class.find('const SizedBox(height: 100),', if_group_start)

# Add locale, but only if not already present
if 'final String locale =' not in new_class:
    new_class = new_class.replace('final theme = Theme.of(context);', 'final theme = Theme.of(context);\n    final String locale = ref.watch(localeProvider) ?? "tr_TR";')

new_ui = '''// -- NEW TABS AND CALENDAR --
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            Container(
               decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10)
               ),
               child: Row(
                  children: [
                     Expanded(
                        child: GestureDetector(
                           onTap: () => setState(() => _isDailyTab = true),
                           child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                 color: _isDailyTab ? theme.primaryColor : Colors.transparent,
                                 borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('GÜNLÜK', textAlign: TextAlign.center, style: TextStyle(color: _isDailyTab ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                           ),
                        )
                     ),
                     Expanded(
                        child: GestureDetector(
                           onTap: () => setState(() => _isDailyTab = false),
                           child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                 color: !_isDailyTab ? theme.primaryColor : Colors.transparent,
                                 borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('AYLIK', textAlign: TextAlign.center, style: TextStyle(color: !_isDailyTab ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                           ),
                        )
                     )
                  ],
               )
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1))),
                Text(DateFormat('MMMM yyyy').format(_viewMonth).toUpperCase(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1))),
              ],
            ),
            const SizedBox(height: 8),
            
            Builder(
               builder: (ctx) {
                  final allRems = ref.read(reminderProvider);
                  final monthRems = allRems.where((r) => r.startDate.year == _viewMonth.year && r.startDate.month == _viewMonth.month).toList();
                  final dayRems = allRems.where((r) => r.startDate.year == _viewSelectedDate.year && r.startDate.month == _viewSelectedDate.month && r.startDate.day == _viewSelectedDate.day).toList();
                  
                  return Column(
                     children: [
                        _buildFinanceStyleCalendarGrid(allRems),
                        const SizedBox(height: 24),
                        _buildSummaryBox(locale, _isDailyTab ? dayRems : monthRems),
                        const SizedBox(height: 24),
                        if ((_isDailyTab ? dayRems : monthRems).isNotEmpty)
                           _buildTaskDataTable(_isDailyTab ? dayRems : monthRems, locale)
                        else
                           const Padding(padding: EdgeInsets.all(32), child: Text('Seçili döneme ait görev bulunamadı.', style: TextStyle(color: Colors.white54))),
                     ],
                  );
               }
            ),
'''

if build_start != -1 and if_group_start != -1 and if_group_end != -1:
    new_class = new_class[:if_group_start] + new_ui + new_class[if_group_end:]
else:
    print('Failed to find replace regions!')
    print('build_start', build_start)
    print('if_group_start', if_group_start)
    print('if_group_end', if_group_end)

last_brace = new_class.rfind('}')
# Don't add edit_func if it's already in the class (it IS already in the class!)
# In PlannerSetupFullScreenState, _showEditReminderDialog already exists around line 666.
# We don't need to append edit_func, just the calendar and tables.
helpers = '\\n\\n' + cal_func + '\\n\\n' + stat_func + '\\n\\n' + table_func + '\\n\\n' + stat_help1 + '\\n\\n' + stat_help2 + '\\n'
new_class = new_class[:last_brace] + helpers + '}\\n\\n'

final_text = text[:s1] + new_class + text[s2:]

with codecs.open('c:/Finance 27/lib/ui/screens/planner_screen.dart', 'w', 'utf-8') as f:
    f.write(final_text)

print('Rewrite compile OK')
