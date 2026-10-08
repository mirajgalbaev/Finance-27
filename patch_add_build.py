import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# We will inject the build method just before Widget _buildExchangeBlock

build_method = '''
  @override
  Widget build(BuildContext context) {
    final trades = ref.watch(tradeProvider);
    final currencySymbol = ref.watch(currencyProvider) == 'USD' ? '\\$' : '₺';
    final locale = ref.watch(localeProvider);
    String dateStr = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(widget.date);

    final tabTrades = trades.where((t) => t.market == _selectedTab).toList();
    final activeExchanges = tabTrades.map((t) => t.exchange).toSet().toList();

    List<Widget> actionButtons = [
      IconButton(
        icon: const Icon(Icons.note_add, color: Colors.greenAccent),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(AppStrings.get(ref, 'daily_notes') ?? 'Günlük Notlar', style: const TextStyle(color: Colors.white)),
              content: TextField(
                controller: _noteController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.get(ref, 'enter_notes_here') ?? 'Notlarınızı buraya yazın...',
                  hintStyle: const TextStyle(color: Colors.white54),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL', style: const TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: () { _saveNotes(); Navigator.pop(ctx); },
                  child: Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET'),
                )
              ]
            )
          );
        }
      ),
      if (!widget.isEmbedded)
        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
    ];

    Widget bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('Futures'),
              const SizedBox(width: 16),
              _buildTabButton('Spot'),
              const SizedBox(width: 16),
              _buildTabButton('MT5'),
            ]
          ),
          const SizedBox(height: 16),
          
          if (_selectedTab == 'Spot')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSpotFilterButton('Günlük'),
                const SizedBox(width: 8),
                _buildSpotFilterButton('Aylık'),
                const SizedBox(width: 8),
                _buildSpotFilterButton('Yıllık'),
              ]
            ),
          const SizedBox(height: 16),
          
          if (activeExchanges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(AppStrings.get(ref, 'no_trades_found') ?? 'Bu piyasa için işlem bulunamadı.', style: const TextStyle(color: Colors.white30, fontSize: 16)),
              ),
            ),
            
          ...activeExchanges.map((exchange) {
            final exchangeTrades = tabTrades.where((t) => t.exchange == exchange).toList();
            if (!_screenshotControllers.containsKey(exchange)) {
               _screenshotControllers[exchange] = ScreenshotController();
            }
            return _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale);
          }).toList(),
          
          if (activeExchanges.isNotEmpty)
            _buildGlobalGrandTotalSummary(tabTrades, currencySymbol),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${AppStrings.get(ref, 'daily_trade_journal') ?? 'Günlük İşlem Kaydı'} - $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                  Row(children: actionButtons),
                ],
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }
  
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('${AppStrings.get(ref, 'daily_trade_journal') ?? 'Günlük İşlem Kaydı'} - $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ...actionButtons,
          const SizedBox(width: 16),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildSpotFilterButton(String filter) {
    bool isSelected = _spotFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _spotFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent)
        ),
        child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.orangeAccent, fontWeight: FontWeight.bold)),
      )
    );
  }

'''

idx = content.find("Widget _buildExchangeBlock(String exchange")
if idx != -1:
    content = content[:idx] + build_method + content[idx:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: Injected build method")
else:
    print("FAILED")
