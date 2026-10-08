import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:intl/intl.dart'; 

import 'package:finance_27/core/localization_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/monthly_stats_provider.dart';

class JarDistributionChart extends ConsumerWidget {
  final List<JarModel> jars;
  final MonthlyStats monthlyStats;
  final Widget? actionArea;

  const JarDistributionChart({
    super.key,
    required this.jars,
    required this.monthlyStats,
    this.actionArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentCurrency = ref.watch(currencyProvider);
    final totalBalance = monthlyStats.jarBalances.values.fold(0.0, (sum, balances) => sum + (balances[currentCurrency] ?? 0.0));
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider));
    
    final period = ref.watch(jarStatusPeriodProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final localeCode = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    
    String centerLabel = '';
    if (period == JarStatusPeriod.monthly) {
      centerLabel = DateFormat.MMMM(localeCode).format(selectedMonth).toUpperCase();
    } else if (period == JarStatusPeriod.yearly) {
      centerLabel = DateFormat.y(localeCode).format(selectedMonth);
    } else {
      centerLabel = AppStrings.get(ref, 'all_time_lifetime') ?? 'LIFETIME';
    }

    return Column(
      children: [
        SizedBox(
          height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 120,
              sections: jars.map((jar) {
                final amount = monthlyStats.jarBalances[jar.type]?[currentCurrency] ?? 0.0;
                final double percent = totalBalance > 0 ? (amount / totalBalance * 100) : 0.0;
                final String percentStr = percent > 0 ? '${percent.toStringAsFixed(1)}%' : '';
                final String displayName = jar.customName ?? AppStrings.get(ref, jar.type.displayName);
                
                return PieChartSectionData(
                  color: _getColorForType(jar.type, theme),
                  value: amount > 0 ? amount : 1,
                  title: '',
                  radius: 35,
                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 55,
                    borderColor: _getColorForType(jar.type, theme),
                    name: displayName,
                    percentage: percentStr,
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
                centerLabel,
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
                final curBalance = monthlyStats.jarBalances.values.fold(0.0, (sum, balances) => sum + (balances[cur] ?? 0.0));
                final formattedAmt = NumberFormat.simpleCurrency(name: cur).format(curBalance);
                
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
        // LEGEND AND TOTALS MOVED BELOW
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(ref, 'total_balance') ?? 'Toplam Bakiye',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(monthlyStats.jarBalances.values.fold(0.0, (sum, balances) => sum + (balances[currentCurrency] ?? 0.0))),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.get(ref, 'expense'),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(monthlyStats.totalExpense[currentCurrency] ?? 0.0),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.white12),
              // 6 JARS
              ...jars.map((jar) {
                final color = _getColorForType(jar.type, theme); 
                final displayName = jar.customName ?? AppStrings.get(ref, jar.type.displayName);
                
                final amount = monthlyStats.jarBalances[jar.type]?[currentCurrency] ?? 0.0;
                final formattedAmt = currencyFormat.format(amount);
                
                final income = monthlyStats.jarIncomes[jar.type]?[currentCurrency] ?? 0.0;
                final expense = monthlyStats.jarExpenses[jar.type]?[currentCurrency] ?? 0.0;
                
                String labelText = '$displayName';
                String percentText = '';
                if (income > 0) {
                   double expensePercent = (expense / income) * 100;
                   if (expensePercent > 100) expensePercent = 100;
                   
                   if (expensePercent > 0) {
                     percentText = ' (-${expensePercent.toStringAsFixed(0)}%)';
                   }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _Badge(
                        icon: _getIconForType(jar.type),
                        size: 24,
                        borderColor: color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[200],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formattedAmt,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (percentText.isNotEmpty)
                              TextSpan(
                                text: percentText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForType(JarType type, ThemeData theme) {
    switch (type) {
      case JarType.necessities:
        return Colors.blue;
      case JarType.financialFreedom:
        return theme.primaryColor;
      case JarType.longTermSavings:
        return Colors.green;
      case JarType.education:
        return Colors.orange;
      case JarType.play:
        return Colors.purple;
      case JarType.giving:
        return Colors.red;
    }
  }

  IconData _getIconForType(JarType type) {
    switch (type) {
      case JarType.necessities:
        return Icons.shopping_cart;
      case JarType.financialFreedom:
        return Icons.trending_up;
      case JarType.longTermSavings:
        return Icons.account_balance_wallet;
      case JarType.education:
        return Icons.school;
      case JarType.play:
        return Icons.sports_esports;
      case JarType.giving:
        return Icons.volunteer_activism;
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;
  final String name;
  final String percentage;

  const _Badge({
    Key? key,
    required this.icon,
    required this.size,
    required this.borderColor,
    this.name = '',
    this.percentage = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: size * 0.35,
            color: borderColor,
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (percentage.isNotEmpty) ...[
            Text(
              percentage,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
