import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:intl/intl.dart';

class RolloverSummaryWidget extends ConsumerWidget {
  const RolloverSummaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jars = ref.watch(jarProvider);
    final transactions = ref.watch(transactionProvider);
    final currency = ref.watch(currencyProvider);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final theme = Theme.of(context);

    final now = DateTime.now();
    
    // Dynamic title: e.g., "Önceki Aylardan Devreden Bakiyeler"
    final String rolloverFromStr = AppStrings.get(ref, 'rollover_title') ?? "Önceki Aylardan Devreden Bakiyeler";

    double totalRollover = 0.0;
    final List<Map<String, dynamic>> rolloverDetails = [];

    for (var jar in jars) {
      // Rollover is what we had strictly before this month began.
      final priorTxs = transactions.where((t) => 
        t.jarType == jar.type && 
        t.currency == currency &&
        (t.date.isBefore(DateTime(now.year, now.month, 1)))
      );

      double rollover = 0.0;
      for (var t in priorTxs) {
        if (t.isIncome) {
          rollover += t.amount;
        } else {
          rollover -= t.amount;
        }
      }

      if (rollover > 0.01) {
        totalRollover += rollover;
        rolloverDetails.add({
          'name': AppStrings.get(ref, jar.customName ?? jar.type.displayName) ?? (jar.customName ?? jar.type.displayName),
          'amount': rollover,
          'color': _getJarColor(jar.type),
        });
      }
    }

    if (totalRollover <= 0.01) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rolloverFromStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${totalRollover.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (rolloverDetails.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rolloverDetails.map((detail) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: detail['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: detail['color'].withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: detail['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${detail['name']}: ',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          '${(detail['amount'] as double).toStringAsFixed(2)}',
                          style: TextStyle(color: detail['color'], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Color _getJarColor(JarType type) {
    switch (type) {
      case JarType.necessities: return Colors.blue;
      case JarType.financialFreedom: return Colors.amber;
      case JarType.longTermSavings: return Colors.green;
      case JarType.education: return Colors.purple;
      case JarType.play: return Colors.pink;
      case JarType.giving: return Colors.teal;
    }
  }
}
