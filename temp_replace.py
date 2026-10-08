import codecs
with codecs.open('c:/Finance 27/lib/ui/screens/replace_ui_v2.py', 'r', 'utf-8') as f:
    text_s = f.read()
repl = text_s[text_s.find('class _PlannerSetupFullScreenState'):text_s.find('\"\"\"', text_s.find('class _PlannerSetupFullScreenState'))]
repl = repl.replace('ConsumerState<_PlannerSetupFullScreen>', 'ConsumerState<PlannerSetupFullScreen>')
repl = repl.replace('widget.selectedDate', 'DateTime.now()')

with codecs.open('c:/Finance 27/lib/ui/screens/planner_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

start = text.find('class _PlannerSetupFullScreenState extends ConsumerState<PlannerSetupFullScreen>')
end = text.find('class _DailyPlanTabState extends ConsumerState<_DailyPlanTab>')

new_text = text[:start] + repl + '\n\n' + text[end:]
with codecs.open('c:/Finance 27/lib/ui/screens/planner_screen.dart', 'w', 'utf-8') as f:
    f.write(new_text)

print('Replaced smoothly!')
