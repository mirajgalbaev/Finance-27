import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/providers/goal_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/core/localization_provider.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    final goal = goals.firstWhere((g) => g.id == goalId, orElse: () => GoalModel(id: '', title: '', targetAmount: 0, deadline: DateTime.now()));
    
    // If goal was deleted or not found
    if (goal.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.get(ref, 'goal_not_found'))),
        body: Center(child: Text(AppStrings.get(ref, 'goal_no_longer_exists'))),
      );
    }

    final theme = Theme.of(context);
    final currencySymbol = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider)).currencySymbol;
    final isCompleted = goal.currentAmount >= goal.targetAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
      ),
      body: isCompleted 
          ? _buildSuccessView(context, ref, goal, theme)
          : _buildProgressView(context, ref, goal, theme, currencySymbol),
      floatingActionButton: isCompleted ? null : FloatingActionButton(
        onPressed: () => _showAddDepositDialog(context, ref, goal),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, WidgetRef ref, GoalModel goal, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 120, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'CONGRATULATIONS! 🎉',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              (AppStrings.get(ref, 'reached_goal_msg') ?? 'You have successfully reached your goal:\n{title}').replaceAll('{title}', goal.title),
              style: const TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get(ref, 'back_to_dashboard'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(BuildContext context, WidgetRef ref, GoalModel goal, ThemeData theme, String currencySymbol) {
    final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final dateFormat = DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.watch(localeProvider)));

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          color: theme.cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  Text(
                    goal.isFinancial 
                        ? '${goal.currency ?? currencySymbol}${goal.currentAmount.toStringAsFixed(2)} / ${goal.currency ?? currencySymbol}${goal.targetAmount.toStringAsFixed(2)}'
                        : '${goal.currentAmount.toStringAsFixed(2)} / ${goal.targetAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.get(ref, 'deadline') ?? 'Deadline'}: ${dateFormat.format(goal.deadline)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    goal.isFinancial
                        ? 'Kalan: $currencySymbol${goal.remainingAmount.toStringAsFixed(2)}'
                        : (AppStrings.get(ref, 'remaining_units') ?? 'Kalan: {amount} Adet').replaceAll('{amount}', goal.remainingAmount.toStringAsFixed(2)),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Deposits List
        Expanded(
          child: goal.deposits.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.get(ref, 'no_deposits_yet') ?? 'No deposits yet. Start saving!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                  itemCount: goal.deposits.length,
                  itemBuilder: (context, index) {
                    // Show newest first
                    final deposit = goal.deposits[goal.deposits.length - 1 - index];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                        child: const Icon(Icons.arrow_downward, color: Colors.greenAccent),
                      ),
                      title: Text(deposit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dateFormat.format(deposit.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            goal.isFinancial
                                ? '+${goal.currency ?? currencySymbol}${deposit.amount.toStringAsFixed(2)}'
                                : '+${deposit.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              ref.read(goalProvider.notifier).deleteDeposit(goal.id, deposit.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddDepositDialog(BuildContext context, WidgetRef ref, GoalModel goal) {
    double amount = 0.0;
    String title = '';
    final currencySymbol = NumberFormat.simpleCurrency(name: ref.read(currencyProvider)).currencySymbol;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(goal.isFinancial ? AppStrings.get(ref, 'add_budget') : AppStrings.get(ref, 'add_progress')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(labelText: goal.isFinancial ? AppStrings.get(ref, 'source_note_fin') ?? 'Kaynak / Not (Örn: Maaş)' : AppStrings.get(ref, 'source_note_prog') ?? 'Not (Örn: 1. Gün Antrenmanı)'),
              onChanged: (value) => title = value,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: goal.isFinancial ? '${goal.currency ?? currencySymbol} ' : '',
                labelText: goal.isFinancial ? (AppStrings.get(ref, 'amount') ?? 'Amount') : AppStrings.get(ref, 'added_units_day') ?? 'Eklenen Adet / Gün',
              ),
              onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get(ref, 'cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amount > 0) {
                ref.read(goalProvider.notifier).addDeposit(goal.id, amount, title.isEmpty ? 'Deposit' : title);
                Navigator.pop(context);
              }
            },
            child: Text(AppStrings.get(ref, 'confirm') ?? 'Confirm'),
          ),
        ],
      ),
    );
  }
}
