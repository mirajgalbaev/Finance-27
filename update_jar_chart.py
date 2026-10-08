import os

settings_path = r"C:\Finance 27\lib\providers\settings_provider.dart"
chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(settings_path, 'r', encoding='utf-8') as f:
    s = f.read()

s = s.replace("CurrencyNotifier() : super('USD')", "CurrencyNotifier() : super('KGS')")
s = s.replace("defaultValue: 'USD'", "defaultValue: 'KGS'")

with open(settings_path, 'w', encoding='utf-8') as f:
    f.write(s)

with open(chart_path, 'r', encoding='utf-8') as f:
    c = f.read()

replacement = """
                  Text(
                    currencyFormat.format(monthlyStats.totalIncome[currentCurrency] ?? 0.0),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.center,
                    children: ['KGS', 'USD', 'EUR', 'TRY', 'RUB'].map((cur) {
                      final isSelected = cur == currentCurrency;
                      final symbol = NumberFormat.simpleCurrency(name: cur).currencySymbol;
                      return GestureDetector(
                        onTap: () {
                          ref.read(currencyProvider.notifier).setCurrency(cur);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purpleAccent : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(symbol, style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
"""

c = c.replace("""                  Text(
                    currencyFormat.format(monthlyStats.totalIncome[currentCurrency] ?? 0.0),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),""", replacement)

with open(chart_path, 'w', encoding='utf-8') as f:
    f.write(c)

print("Updated settings and jar chart")
