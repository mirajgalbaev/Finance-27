import os

chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(chart_path, 'r', encoding='utf-8') as f:
    c = f.read()

replacement = """              Column(
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
"""

start_str = "              Column(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Text(\n                    DateFormat.MMMM"
end_str = "                  }).toList(),\n                ),\n              ),\n              Column("

# We actually want to replace everything from the first Column to the end of the second Column.
# Let's just find the first Column block and replace it manually.

lines = c.split('\n')
start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "Column(" in line and "mainAxisSize: MainAxisSize.min" in lines[i+1] and "DateFormat.MMMM" in lines[i+3]:
        start_idx = i
        break

if start_idx != -1:
    count = 0
    # count until we hit `],` and `),` that matches this column
    for i in range(start_idx, len(lines)):
        if "if (actionArea != null)" in lines[i]:
            # we went too far, let's step back to the first `            ],` before this
            for j in range(i, start_idx, -1):
                if lines[j].strip() == "]," and lines[j+1].strip() == ")," and lines[j+2].strip() == "),":
                    end_idx = j
                    break
            break

if start_idx != -1 and end_idx != -1:
    # replace lines[start_idx:end_idx] with replacement
    new_c = '\n'.join(lines[:start_idx]) + "\n" + replacement + '\n'.join(lines[end_idx:])
    with open(chart_path, 'w', encoding='utf-8') as f:
        f.write(new_c)
    print("Fixed jar chart duplicate Column")
else:
    print("Could not find bounds", start_idx, end_idx)
