import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _showAddTradeDialog
method_str = '''
  void _showAddTradeDialog() {
    showDialog(context: context, builder: (context) => AddTradeDialog(date: widget.date, initialMarket: _selectedTab));
  }

  @override
'''
content = content.replace("  @override\n  Widget build(BuildContext context) {", method_str + "  Widget build(BuildContext context) {")

# Add the button to actionButtons
btn_str = '''
    List<Widget> actionButtons = [
      ElevatedButton.icon(
        onPressed: _showAddTradeDialog,
        icon: const Icon(Icons.add, size: 18),
        label: Text(AppStrings.get(ref, 'new_trade') ?? 'Yeni İşlem'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
'''
content = content.replace("    List<Widget> actionButtons = [", btn_str)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Added Yeni Islem button")
