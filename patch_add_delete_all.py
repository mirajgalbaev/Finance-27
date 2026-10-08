import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _showResetConfirmationDialog
method_str = '''
  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text((AppStrings.get(ref, 'delete_all_trades_title') ?? 'Tüm "{tab}" İşlemlerini Sil').replaceAll('{tab}', _selectedTab), style: const TextStyle(color: Colors.white)),
        content: Text((AppStrings.get(ref, 'confirm_delete_all_trades') ?? 'Emin misiniz? Geçmiş ve Gelecek TÜM {tab} işlemleri kalıcı olarak silinecektir.').replaceAll('{tab}', _selectedTab), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL', style: const TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(tradeProvider.notifier).deleteAllTradesByMarket(_selectedTab);
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TÜMÜNÜ SİL', style: const TextStyle(color: Colors.white)),
          )
        ]
      )
    );
  }

  void _showAddTradeDialog() {
'''
content = content.replace("  void _showAddTradeDialog() {", method_str)

# Add the delete all button to actionButtons
btn_str = '''
    List<Widget> actionButtons = [
      IconButton(
        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
        onPressed: () => _showResetConfirmationDialog(context, ref),
      ),
      ElevatedButton.icon(
'''
content = content.replace("    List<Widget> actionButtons = [\n      ElevatedButton.icon(", btn_str)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESS: Added delete all button")
