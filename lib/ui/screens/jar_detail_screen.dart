import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:finance_27/providers/monthly_stats_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/models/transaction_model.dart';

final jarDetailSelectedDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);
final jarDetailSelectedCurrencyProvider = StateProvider.autoDispose<String?>((ref) => null);

class JarDetailScreen extends ConsumerWidget {
  final JarType jarType;
  final double? currentMonthBalance;

  const JarDetailScreen({
    super.key,
    required this.jarType,
    this.currentMonthBalance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jars = ref.watch(jarProvider);
    final monthlyStats = ref.watch(monthlyStatsProvider);
    final jar = jars.firstWhere((j) => j.type == jarType);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider));
    
    final currentCurrency = ref.watch(currencyProvider);
    final double liveBalance = monthlyStats.jarBalances[jarType]?[currentCurrency] ?? (currentMonthBalance ?? (jar.balances[currentCurrency] ?? 0.0));
    
    final period = ref.watch(jarStatusPeriodProvider);
    final localeCode = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final selectedDay = ref.watch(jarDetailSelectedDateProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    
    String headerText = '';
    if (selectedDay != null) {
      headerText = DateFormat.yMMMMd(localeCode).format(selectedDay);
    } else if (period == JarStatusPeriod.monthly) {
      headerText = DateFormat.MMMM(localeCode).format(selectedMonth).toUpperCase();
    } else if (period == JarStatusPeriod.yearly) {
      headerText = DateFormat.y(localeCode).format(selectedMonth);
    } else {
      headerText = AppStrings.get(ref, 'all_time_lifetime') ?? 'LIFETIME';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(jar.customName ?? AppStrings.get(ref, jar.type.displayName)),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (period != JarStatusPeriod.lifetime)
                        InkWell(
                          onTap: () {
                            ref.read(jarDetailSelectedDateProvider.notifier).state = null;
                            ref.read(selectedMonthProvider.notifier).update((state) {
                               if (period == JarStatusPeriod.yearly) return DateTime(state.year - 1, state.month, 1);
                               return DateTime(state.year, state.month - 1, 1);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chevron_left, color: theme.primaryColor, size: 24),
                          ),
                        ),
                      if (period != JarStatusPeriod.lifetime) const SizedBox(width: 16),
                      InkWell(
                        onTap: period == JarStatusPeriod.lifetime ? null : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDay ?? selectedMonth,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDatePickerMode: period == JarStatusPeriod.yearly ? DatePickerMode.year : DatePickerMode.day,
                          );
                          if (picked != null) {
                            if (period == JarStatusPeriod.yearly) {
                              ref.read(jarDetailSelectedDateProvider.notifier).state = null;
                              ref.read(selectedMonthProvider.notifier).state = DateTime(picked.year, 1, 1);
                            } else {
                              ref.read(jarDetailSelectedDateProvider.notifier).state = picked;
                              ref.read(selectedMonthProvider.notifier).state = DateTime(picked.year, picked.month, 1);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                headerText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (selectedDay != null) ...[
                                InkWell(
                                  onTap: () => ref.read(jarDetailSelectedDateProvider.notifier).state = null,
                                  child: Icon(Icons.close, color: theme.primaryColor, size: 16),
                                ),
                              ] else if (period != JarStatusPeriod.lifetime) ...[
                                Icon(Icons.calendar_month, color: theme.primaryColor, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (period != JarStatusPeriod.lifetime) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            ref.read(jarDetailSelectedDateProvider.notifier).state = null;
                            ref.read(selectedMonthProvider.notifier).update((state) {
                               if (period == JarStatusPeriod.yearly) return DateTime(state.year + 1, state.month, 1);
                               return DateTime(state.year, state.month + 1, 1);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chevron_right, color: theme.primaryColor, size: 24),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: ['KGS', 'USD', 'EUR', 'TRY', 'RUB'].map((currency) {
                      final amount = monthlyStats.jarBalances[jarType]?[currency] ?? jar.balances[currency] ?? 0.0;
                      final isSelected = ref.watch(jarDetailSelectedCurrencyProvider) == currency;
                      return InkWell(
                        onTap: () {
                          final current = ref.read(jarDetailSelectedCurrencyProvider);
                          ref.read(jarDetailSelectedCurrencyProvider.notifier).state = current == currency ? null : currency;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? theme.primaryColor.withOpacity(0.5) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$currency ',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.4),
                                ),
                              ),
                              Text(
                                '${NumberFormat.simpleCurrency(name: currency).currencySymbol}${amount.toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.15), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, color: theme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppStrings.get(ref, 'jar_info').replaceAll('%s', '${(jar.allocationPercentage * 100).toInt()}%'),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? Colors.grey[400], 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.get(ref, 'actions'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                _buildActionCard(
                  context,
                  AppStrings.get(ref, 'add_income'),
                  Icons.add_chart,
                  Colors.green,
                  () => _showTransactionDialog(context, ref, true),
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  AppStrings.get(ref, 'record_expense'),
                  Icons.payment,
                  Colors.redAccent,
                  () => _showTransactionDialog(context, ref, false, double.infinity),
                ),
              ],
            ),
            _buildTransactionSplitView(context, ref, jarType),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionSplitView(BuildContext context, WidgetRef ref, JarType type) {
    final transactions = ref.watch(transactionProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedDay = ref.watch(jarDetailSelectedDateProvider);
    final filterCurrency = ref.watch(jarDetailSelectedCurrencyProvider);
    
    final period = ref.watch(jarStatusPeriodProvider);
    
    final viewTransactions = transactions.where((t) {
      if (t.jarType != type) return false;
      if (filterCurrency != null && t.currency != filterCurrency) return false;
      if (selectedDay != null) {
        return t.date.year == selectedDay.year && 
               t.date.month == selectedDay.month && 
               t.date.day == selectedDay.day;
      }
      if (period == JarStatusPeriod.monthly) return t.date.month == selectedMonth.month && t.date.year == selectedMonth.year;
      if (period == JarStatusPeriod.yearly) return t.date.year == selectedMonth.year;
      return true; // Lifetime
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final incomes = viewTransactions.where((t) => t.isIncome).toList();
    final expenses = viewTransactions.where((t) => !t.isIncome).toList();
    
    if (period != JarStatusPeriod.lifetime) {
      final rollovers = ref.watch(monthlyStatsProvider).jarRollovers[type] ?? {};
      for (var entry in rollovers.entries) {
        if (filterCurrency != null && entry.key != filterCurrency) continue;
        if (entry.value > 0) {
          incomes.insert(0, TransactionModel(
            id: 'rollover_${entry.key}',
            amount: entry.value,
            date: selectedDay ?? selectedMonth,
            isIncome: true,
            jarType: type,
            title: AppStrings.get(ref, period == JarStatusPeriod.yearly ? 'rollover_yearly' : 'rollover_monthly') ?? 'Geçmiş Aydan Kalan',
            currency: entry.key,
          ));
        }
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTransactionList(context, ref, AppStrings.get(ref, 'income') ?? 'Income', incomes, true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTransactionList(context, ref, AppStrings.get(ref, 'expense') ?? 'Expense', expenses, false),
        ),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context, WidgetRef ref, String title, List<dynamic> transactions, bool isIncome) {
    final theme = Theme.of(context);
    final localeCode = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final dateFormat = DateFormat('MMM d, HH:mm', AppStrings.getDateFormatLocale(localeCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Text(
            AppStrings.get(ref, 'no_transactions') ?? 'No History',
            style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(color: theme.primaryColor.withOpacity(0.1)),
            itemBuilder: (context, index) {
              final t = transactions[index];
              final bgColor = isIncome ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05);
              final borderColor = isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2);
              final iconColor = isIncome ? Colors.greenAccent : Colors.redAccent;
              
              final tCurrencySymbol = NumberFormat.simpleCurrency(name: t.currency).currencySymbol;
              final amountText = '${isIncome ? '+' : '-'}$tCurrencySymbol${t.amount.toStringAsFixed(0)}';
                
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (t.title == 'Income' || t.title == 'Expense') 
                                    ? NumberFormat.simpleCurrency(name: t.currency).currencySymbol 
                                    : t.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(t.date),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amountText,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!t.id.startsWith('rollover_'))
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      final currentJar = ref.read(jarProvider).firstWhere((j) => j.type == t.jarType);
                                      _showEditTransactionDialog(context, ref, t, isIncome, 
                                        isIncome ? double.infinity : ((currentJar.balances[t.currency] ?? 0.0) + t.amount));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit, size: 14, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Theme.of(context).cardColor,
                                          title: Text(AppStrings.get(ref, 'confirm_delete') ?? 'Delete Transaction?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: Text(AppStrings.get(ref, 'cancel') ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                ref.read(jarProvider.notifier).deleteJarTransaction(t);
                                                Navigator.pop(ctx);
                                              },
                                              child: Text(AppStrings.get(ref, 'delete') ?? 'Delete', style: const TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete, size: 14, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showTransactionDialog(BuildContext context, WidgetRef ref, bool isIncome, [double maxAmount = double.infinity]) {
    double amount = 0.0;
    String title = '';
    String selectedCurrency = 'KGS';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(isIncome ? AppStrings.get(ref, 'add_income') : AppStrings.get(ref, 'record_expense')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'source_optional') ?? 'Title (e.g. Taxi)',
                    ),
                    onChanged: (value) => title = value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppStrings.get(ref, 'amount'),
                          ),
                          onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCurrency,
                            items: [
                              DropdownMenuItem(value: 'KGS', child: Text('KGS (с)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                              DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                              DropdownMenuItem(value: 'TRY', child: Text('TRY (₺)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                              DropdownMenuItem(value: 'RUB', child: Text('RUB (₽)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedCurrency = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.get(ref, 'cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (amount > 0) {
                      if (!isIncome && amount > maxAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppStrings.get(ref, 'insufficient_funds') ?? 'Cannot exceed jar balance'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      if (isIncome) {
                        ref.read(jarProvider.notifier).addJarIncome(jarType, amount, title, selectedCurrency);
                      } else {
                        ref.read(jarProvider.notifier).recordExpense(jarType, amount, title, selectedCurrency);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(AppStrings.get(ref, 'confirm')),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showEditTransactionDialog(BuildContext context, WidgetRef ref, dynamic transaction, bool isIncome, double maxAmount) {
    double tempAmount = transaction.amount;
    String tempTitle = transaction.title;
    final titleController = TextEditingController(text: tempTitle);
    final amountController = TextEditingController(text: tempAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppStrings.get(ref, 'edit') ?? 'Edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppStrings.get(ref, 'source_optional') ?? 'Title (e.g. Taxi)',
              ),
              onChanged: (value) => tempTitle = value,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${NumberFormat.simpleCurrency(name: transaction.currency).currencySymbol} ',
                labelText: AppStrings.get(ref, 'amount'),
              ),
              onChanged: (value) => tempAmount = double.tryParse(value) ?? transaction.amount,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get(ref, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempAmount > 0) {
                if (!isIncome && tempAmount > maxAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppStrings.get(ref, 'insufficient_funds') ?? 'Cannot exceed jar balance'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                ref.read(jarProvider.notifier).editJarTransaction(transaction, tempTitle, tempAmount);
                Navigator.pop(context);
              }
            },
            child: Text(AppStrings.get(ref, 'edit') ?? 'Edit'),
          ),
        ],
      ),
    );
  }
}
