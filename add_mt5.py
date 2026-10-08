import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Find the _buildTradesAnalytics() method completely
# We know it starts with "Widget _buildTradesAnalytics() {"
# and ends right before "Widget _buildSpotAnalytics() {"

start_str = "Widget _buildTradesAnalytics() {"
end_str = "Widget _buildSpotAnalytics() {"

start_idx = text.find(start_str)
end_idx = text.find(end_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find the bounds.")
else:
    trades_code = text[start_idx:end_idx]
    
    # 2. Modify it for MT5
    mt5_code = trades_code.replace("Widget _buildTradesAnalytics()", "Widget _buildMT5Analytics()")
    mt5_code = mt5_code.replace("t.market == 'Futures'", "t.market == 'MT5'")
    mt5_code = mt5_code.replace("totalFuturesInvested", "totalMT5Invested")
    mt5_code = mt5_code.replace("totalFuturesBudget", "totalMT5Budget")
    
    # 3. Insert it into the file
    new_text = text[:end_idx] + mt5_code + text[end_idx:]
    
    # 4. Modify buildExportContent() to call it
    # Find:
    #                       _buildSpotAnalytics(),
    #                       const SizedBox(height: 16),
    #                       _buildTasksAnalytics(),
    
    inject_point = r"_buildSpotAnalytics\(\),\s*const SizedBox\(height: 16\),"
    replace_str = "_buildSpotAnalytics(),\n                      const SizedBox(height: 16),\n                      _buildSectionTitle('MT5 ANALIZI (Forex & Emtia)'),\n                      const SizedBox(height: 16),\n                      _buildMT5Analytics(),\n                      const SizedBox(height: 16),"
    
    new_text = re.sub(inject_point, replace_str, new_text, count=1)
    
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Successfully added _buildMT5Analytics!")
