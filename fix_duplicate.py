import io
import re

path = 'lib/ui/screens/analytics_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# I want to find the SECOND instance of `Widget _buildLegendItem` and remove it entirely.
# Wait, let's just find the `Widget _buildLegendItem` inside the MT5 block or just after it.
# Actually, the block that was duplicated starts with `Widget _buildLegendItem` and ends at `Widget _buildSpotAnalytics() {` or something.

start_str = "Widget _buildMT5Analytics() {"
end_str = "Widget _buildSpotAnalytics() {"

start_idx = text.find(start_str)
end_idx = text.find(end_str, start_idx)

mt5_block = text[start_idx:end_idx]

# Inside mt5_block, let's remove `Widget _buildLegendItem` until its closing brace.
# We know the duplicated legend item function looks like:
#   Widget _buildLegendItem(String title, String value, Color color) {
#       return Row(...
#       );
#     }
# Let's use regex to remove it from mt5_block.

pattern = r"\s*Widget _buildLegendItem\(String title, String value, Color color\) \{.*?\n  \}"
mt5_block_clean = re.sub(pattern, "", mt5_block, flags=re.DOTALL)

new_text = text[:start_idx] + mt5_block_clean + text[end_idx:]

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Removed duplicate _buildLegendItem")
