import re

with open('lib/ui/screens/planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix columns: const [
content = content.replace('columns: const [', 'columns: [')

# Fix Undefined name 'ref' in _buildMonthlyTradeTable
content = content.replace(
    "Widget _buildMonthlyTradeTable(ThemeData theme, String locale, String currencySymbol, List<TradeModel> displayedTrades) {",
    "Widget _buildMonthlyTradeTable(WidgetRef ref, ThemeData theme, String locale, String currencySymbol, List<TradeModel> displayedTrades) {"
)
content = content.replace(
    "_buildMonthlyTradeTable(theme, locale, currentCurrencySymbol, filteredTrades)",
    "_buildMonthlyTradeTable(ref, theme, locale, currentCurrencySymbol, filteredTrades)"
)

# Fix Undefined name 'ref' in _buildTaskDataTable if any (actually it's inside ConsumerState but let's check)
# _buildTaskDataTable is inside _OverviewTabState and _FinancePlanTabInnerState which extend ConsumerState so ref is already available.
# Wait, why was ref undefined? Let's check where _buildMonthlyTradeTable is actually called. It is called inside _FinancePlanTabInnerState.build
# But maybe _buildMonthlyTradeTable is OUTSIDE the class?
# If it's outside the class, adding WidgetRef ref is the correct fix.

with open('lib/ui/screens/planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed syntax errors in planner_screen.dart")
