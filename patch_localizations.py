import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1080, 1920)),
            child: Container(
              width: 1080,
              height: 1920,
              color: const Color(0xFF0F172A),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 1080,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                          _buildGlobalGrandTotalSummary(trades, currencySymbol),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );'''

new_code = '''      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1080, 1920)),
              child: Theme(
                data: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: const Color(0xFF0F172A),
                ),
                child: Container(
                  width: 1080,
                  height: 1920,
                  color: const Color(0xFF0F172A),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 1080,
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                              _buildGlobalGrandTotalSummary(trades, currencySymbol),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );'''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Wrapped widget in Localizations and Theme")
