import os

path = 'lib/ui/widgets/mt5_calculator_widget.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''  @override
  void initState() {
    super.initState();
    widget.pairCtrl.text = _selectedSymbol;
    widget.onTypeChanged(_direction);
    widget.entryCtrl.addListener(_calculate);'''

replacement = '''  @override
  void initState() {
    super.initState();
    widget.pairCtrl.text = _selectedSymbol;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTypeChanged(_direction);
    });
    widget.entryCtrl.addListener(_calculate);'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS")
