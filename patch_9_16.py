import re

path = 'lib/ui/screens/daily_trade_journal_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the ViewConfiguration in _captureOffScreenWidget
old_view_config = '''      configuration: const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(width: 1080, height: 5000),
        physicalConstraints: BoxConstraints.tightFor(width: 1080 * 2.0, height: 5000 * 2.0),
        devicePixelRatio: 2.0,
      ),'''

new_view_config = '''      configuration: const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(width: 1080, height: 1920),
        physicalConstraints: BoxConstraints.tightFor(width: 1080 * 2.0, height: 1920 * 2.0),
        devicePixelRatio: 2.0,
      ),'''

content = content.replace(old_view_config, new_view_config)

# 2. Update widgetToCapture in _exportScreenshot
old_widget_capture = '''      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1080, 5000)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 1080,
                  child: Material(
                color: const Color(0xFF0F172A),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                ),
              ),
                ),
              ],
            ),
          ),
        ),
      );'''

new_widget_capture = '''      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1080, 1920)),
            child: Container(
              width: 1080,
              height: 1920,
              color: const Color(0xFF0F172A),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );'''

content = content.replace(old_widget_capture, new_widget_capture)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: 9:16 exact size applied with OverflowBox")
