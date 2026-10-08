import os

chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(chart_path, 'r', encoding='utf-8') as f:
    c = f.read()

replacement = """
                  Text(
                    DateFormat.MMMM(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(ref.watch(selectedMonthProvider)).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...['KGS', 'USD', 'EUR', 'TRY', 'RUB'].where((cur) {
                    final income = monthlyStats.totalIncome[cur] ?? 0.0;
                    final balance = monthlyStats.jarBalances.values.fold(0.0, (sum, balances) => sum + (balances[cur] ?? 0.0));
                    return income > 0 || balance > 0 || cur == currentCurrency;
                  }).map((cur) {
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
"""

start_str = "Text(\n                    DateFormat.MMMM(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(ref.watch(selectedMonthProvider)).toUpperCase(),"
end_str = "}).toList(),\n                  ),"

start_idx = c.find(start_str)
end_idx = c.find(end_str) + len(end_str)

if start_idx != -1 and end_idx != -1:
    new_c = c[:start_idx] + replacement.strip() + c[end_idx:]
    with open(chart_path, 'w', encoding='utf-8') as f:
        f.write(new_c)
    print("Updated jar chart middle section")
else:
    print("Could not find replacement block")
