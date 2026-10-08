import codecs

file_path = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    text = f.read()

# Fix literal '\n' characters leaking into code
text = text.replace(r'\n\nWidget _buildFinanceStyleCalendarGrid', '\n\n  Widget _buildFinanceStyleCalendarGrid')
text = text.replace(r'  }\n\nWidget _buildSummaryBox', '  }\n\n  Widget _buildSummaryBox')
text = text.replace(r'  }\n\nWidget _buildTaskDataTable', '  }\n\n  Widget _buildTaskDataTable')
text = text.replace(r'  }\n\nColor _getPerformanceColor', '  }\n\n  Color _getPerformanceColor')
text = text.replace(r'  }\n\nWidget _buildStatBox', '  }\n\n  Widget _buildStatBox')
text = text.replace(r'  }\n}\n\nclass _DailyPlanTabState', '  }\n}\n\nclass _DailyPlanTabState')

# Fix extra brackets around 970
bad_brackets = """            ),

                ),
              ),
            ],
            const SizedBox(height: 100),"""

good_brackets = """            ),
            const SizedBox(height: 100),"""

text = text.replace(bad_brackets, good_brackets)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(text)

print("Syntax fix applied.")
