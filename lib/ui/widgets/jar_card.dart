import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:intl/intl.dart';
import 'package:finance_27/providers/monthly_stats_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';

class JarCard extends ConsumerWidget {
  final JarModel jar;
  final Map<String, double>? currentMonthBalances;
  final VoidCallback? onTap;

  const JarCard({
    super.key,
    required this.jar,
    this.currentMonthBalances,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(jarStatusPeriodProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final localeCode = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    
    String topLabel = '';
    if (period == JarStatusPeriod.monthly) {
      topLabel = DateFormat.MMMM(localeCode).format(selectedMonth).toUpperCase();
    } else if (period == JarStatusPeriod.yearly) {
      topLabel = DateFormat.y(localeCode).format(selectedMonth);
    } else {
      topLabel = AppStrings.get(ref, 'all_time_lifetime') ?? 'LIFETIME';
    }

    final Map<String, double> displayBalances = currentMonthBalances ?? jar.balances;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Month and Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  topLabel.toUpperCase(),
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  jar.customName ?? AppStrings.get(ref, jar.type.displayName),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            
            // Middle: Large Icon and Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(jar.type),
                    color: theme.primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${(jar.allocationPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom: Balances and Progress Bar
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...['KGS', 'USD', 'EUR', 'TRY', 'RUB'].map((currency) {
                        final amount = displayBalances[currency] ?? 0.0;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            '${NumberFormat.simpleCurrency(name: currency).currencySymbol}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: jar.allocationPercentage,
                backgroundColor: theme.primaryColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
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
