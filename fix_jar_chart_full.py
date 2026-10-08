import os

chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(chart_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "child: Stack(" in line:
        start_idx = i
    if "// LEGEND AND TOTALS MOVED BELOW" in line:
        end_idx = i
        break

replacement = """      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 75,
              sections: jars.map((jar) {
                final amount = monthlyStats.jarBalances[jar.type]?[currentCurrency] ?? 0.0;
                return PieChartSectionData(
                  color: _getColorForType(jar.type, theme),
                  value: amount > 0 ? amount : 1,
                  title: '',
                  radius: 35,
                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 26,
                    borderColor: _getColorForType(jar.type, theme),
                  ),
                  badgePositionPercentageOffset: 1.25,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.MMMM(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(ref.watch(selectedMonthProvider)).toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...['KGS', 'USD', 'EUR', 'TRY', 'RUB'].map((cur) {
                final isSelected = cur == currentCurrency;
                final income = monthlyStats.totalIncome[cur] ?? 0.0;
                final formattedAmt = NumberFormat.simpleCurrency(name: cur).format(income);
                
                return GestureDetector(
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(cur);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purpleAccent.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.transparent, width: 1),
                    ),
                    child: Text(
                      formattedAmt, 
                      style: TextStyle(
                        fontSize: isSelected ? 15 : 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white54,
                      )
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    ),
    if (actionArea != null) ...[
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: actionArea!,
      ),
    ],
    const SizedBox(height: 32),
"""

if start_idx != -1 and end_idx != -1:
    new_c = "".join(lines[:start_idx]) + replacement + "".join(lines[end_idx:])
    with open(chart_path, 'w', encoding='utf-8') as f:
        f.write(new_c)
    print("Fixed jar chart structure completely")
else:
    print("Could not find bounds", start_idx, end_idx)
