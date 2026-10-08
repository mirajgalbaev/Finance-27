import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/goal_provider.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/ui/screens/goal_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider));

    final activeFinGoals = goals.where((g) => g.currentAmount < g.targetAmount && g.isFinancial).toList();
    final activeProgGoals = goals.where((g) => g.currentAmount < g.targetAmount && !g.isFinancial).toList();
    final completedFinGoals = goals.where((g) => g.currentAmount >= g.targetAmount && g.isFinancial).toList();
    final completedProgGoals = goals.where((g) => g.currentAmount >= g.targetAmount && !g.isFinancial).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(ref, 'goals') ?? 'Goals'),
      ),
      body: goals.isEmpty
          ? _buildEmptyState(ref, theme)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeFinGoals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppStrings.get(ref, 'active_fin_goals') ?? 'Aktif Finansal Hedefler',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...activeFinGoals.map((goal) => _buildGoalCard(context, ref, goal, theme, currencyFormat, false)),
                ],
                if (activeProgGoals.isNotEmpty) ...[
                  if (activeFinGoals.isNotEmpty) const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppStrings.get(ref, 'active_prog_goals') ?? 'Aktif İlerleme Hedefleri',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...activeProgGoals.map((goal) => _buildGoalCard(context, ref, goal, theme, currencyFormat, false)),
                ],
                if (completedFinGoals.isNotEmpty) ...[
                  if (activeFinGoals.isNotEmpty || activeProgGoals.isNotEmpty) const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppStrings.get(ref, 'completed_fin_goals') ?? 'Tamamlanan Finansal Hedefler',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ...completedFinGoals.map((goal) => _buildGoalCard(context, ref, goal, theme, currencyFormat, true)),
                ],
                if (completedProgGoals.isNotEmpty) ...[
                  if (activeFinGoals.isNotEmpty || activeProgGoals.isNotEmpty || completedFinGoals.isNotEmpty) const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppStrings.get(ref, 'completed_prog_goals') ?? 'Tamamlanan İlerleme Hedefleri',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ...completedProgGoals.map((goal) => _buildGoalCard(context, ref, goal, theme, currencyFormat, true)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: Text(
          AppStrings.get(ref, 'add_goal') ?? 'Add Goal',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(WidgetRef ref, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            AppStrings.get(ref, 'no_goals_yet'),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get(ref, 'define_goals'),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalModel goal, ThemeData theme, NumberFormat format, bool isCompleted) {
    final progress = goal.currentAmount / goal.targetAmount;
    final displayFormat = goal.currency != null ? NumberFormat.currency(symbol: goal.currency, decimalDigits: 0) : format;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goal.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.withOpacity(0.05) : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? Colors.green.withOpacity(0.3) : theme.primaryColor.withOpacity(0.1),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      onPressed: () => _showEditGoalDialog(context, ref, goal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => ref.read(goalProvider.notifier).deleteGoal(goal.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  goal.isFinancial
                      ? '${displayFormat.format(goal.currentAmount)} / ${displayFormat.format(goal.targetAmount)}'
                      : '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)} ${AppStrings.get(ref, 'units') ?? 'Adet'}',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : theme.primaryColor),
            ),
            const SizedBox(height: 12),
              if (isCompleted) ...[
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.get(ref, 'goal_completed') ?? 'Goal Completed!',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (goal.completedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(goal.createdAt)} - ${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(goal.completedAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Builder(
                  builder: (context) {
                    final daysTaken = goal.completedAt!.difference(goal.createdAt).inDays;
                    final daysEarly = goal.deadline.difference(goal.completedAt!).inDays;
                    final displayDays = daysTaken <= 0 ? 1 : daysTaken;
                    
                    String message = '${AppStrings.get(ref, 'completed_in')} $displayDays ${AppStrings.get(ref, 'days')}.';
                    if (daysEarly > 0) {
                      message += ' ${AppStrings.get(ref, 'early_completion_praise').replaceAll('{days}', daysEarly.toString())}';
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  }
                ),
              ],
            ] else ...[
              Text(
                '${AppStrings.get(ref, 'deadline')}: ${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(goal.deadline)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (goal.isFinancial)
                Text(
                  '${AppStrings.get(ref, 'daily_target')}: ${displayFormat.format(goal.requiredDailySaving)} • ${AppStrings.get(ref, 'monthly_target')}: ${displayFormat.format(goal.requiredDailySaving * 30)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              else
                Text(
                  (AppStrings.get(ref, 'daily_target_units') ?? 'Günlük Hedef: {daily} Adet • Aylık: {monthly} Adet').replaceAll('{daily}', goal.requiredDailySaving.toStringAsFixed(2)).replaceAll('{monthly}', (goal.requiredDailySaving * 30).toStringAsFixed(2)),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    String title = '';
    double target = 0.0;
    bool isFinancial = true;
    bool isManualDate = false;
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.read(currencyProvider));
    String selectedCurrency = currencyFormat.currencySymbol;
    if (selectedCurrency == 'с') selectedCurrency = 'Сом';
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          
          if (!isManualDate) {
             if (!isFinancial && target > 0) {
                deadline = DateTime.now().add(Duration(days: target.toInt()));
             } else if (isFinancial) {
                deadline = DateTime.now().add(const Duration(days: 30));
             }
          }

          return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppStrings.get(ref, 'add_goal') ?? 'Add Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(isFinancial ? (AppStrings.get(ref, 'fin_goal_label') ?? 'Finansal Hedef') : (AppStrings.get(ref, 'prog_goal_label') ?? 'İlerleme Hedefi (Örn: Dil Öğrenme)'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: isFinancial,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.blueAccent.withOpacity(0.3),
                  onChanged: (val) => setState(() => isFinancial = val),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(
                  decoration: InputDecoration(labelText: AppStrings.get(ref, 'goal_title').replaceAll('\$', selectedCurrency)),
                  onChanged: (value) => title = value,
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(labelText: isFinancial ? selectedCurrency : (AppStrings.get(ref, 'units') ?? (AppStrings.get(ref, 'units') ?? 'Adet'))),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  onChanged: (value) {
                    setState(() {
                       target = double.tryParse(value) ?? 0.0;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                if (isFinancial) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['\$', '€', '₺', '₽', 'Сом'].contains(selectedCurrency) ? selectedCurrency : '\$',
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'currency') ?? 'Para Birimi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '€', child: Text('EUR (€)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '₺', child: Text('TRY (₺)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '₽', child: Text('RUB (₽)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Сом', child: Text('KGS (Сом)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCurrency = val);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() {
                        deadline = picked;
                        isManualDate = true;
                      });
                    }
                  },
                  child: Text(deadline == null 
                    ? AppStrings.get(ref, 'select_deadline') 
                    : '${AppStrings.get(ref, 'deadline')}: ${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.read(localeProvider))).format(deadline!)}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get(ref, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty && target > 0 && deadline != null) {
                  if (!isFinancial) {
                    final now = DateTime.now();
                    final from = DateTime(now.year, now.month, now.day);
                    final to = DateTime(deadline!.year, deadline!.month, deadline!.day);
                    int days = to.difference(from).inDays;
                    if (days <= 0) days = 1;
                    if (target / days < 1.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.get(ref, 'goal_not_approved') ?? 'Hedef Onaylanmadı: İlerleme hedeflerinde günlük hedef en az 1 adet olmalıdır. Lütfen daha yakın bir tarih seçin veya hedef adedini artırın.'),
                          backgroundColor: Colors.redAccent,
                        )
                      );
                      return;
                    }
                  }
                  ref.read(goalProvider.notifier).addGoal(title, target, deadline!, isFinancial: isFinancial, currency: selectedCurrency);
                  Navigator.pop(context);
                }
              },
              child: Text(AppStrings.get(ref, 'create') ?? 'Create'),
            ),
          ],
        );
        }
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, GoalModel goal) {
    String title = goal.title;
    double target = goal.targetAmount;
    bool isFinancial = goal.isFinancial;
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.read(currencyProvider));
    String selectedCurrency = goal.currency ?? currencyFormat.currencySymbol;
    if (selectedCurrency == 'с') selectedCurrency = 'Сом';
    DateTime? deadline = goal.deadline;
    final titleController = TextEditingController(text: title);
    final targetController = TextEditingController(text: target.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppStrings.get(ref, 'edit_goal') ?? 'Edit Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(isFinancial ? (AppStrings.get(ref, 'fin_goal_label') ?? 'Finansal Hedef') : (AppStrings.get(ref, 'prog_goal_label') ?? 'İlerleme Hedefi (Örn: Dil Öğrenme)'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: isFinancial,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.blueAccent.withOpacity(0.3),
                  onChanged: (val) => setState(() => isFinancial = val),
                  contentPadding: EdgeInsets.zero,
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: AppStrings.get(ref, 'goal_title').replaceAll('\$', selectedCurrency)),
                  onChanged: (value) => title = value,
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(labelText: isFinancial ? selectedCurrency : (AppStrings.get(ref, 'units') ?? (AppStrings.get(ref, 'units') ?? 'Adet'))),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  onChanged: (value) {
                    setState(() {
                      target = double.tryParse(value) ?? goal.targetAmount;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                if (isFinancial) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['\$', '€', '₺', '₽', 'Сом'].contains(selectedCurrency) ? selectedCurrency : '\$',
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'currency') ?? 'Para Birimi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '€', child: Text('EUR (€)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '₺', child: Text('TRY (₺)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: '₽', child: Text('RUB (₽)', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Сом', child: Text('KGS (Сом)', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCurrency = val);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => deadline = picked);
                  },
                  child: Text(deadline == null 
                    ? AppStrings.get(ref, 'select_deadline') 
                    : '${AppStrings.get(ref, 'deadline')}: ${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.read(localeProvider))).format(deadline!)}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get(ref, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty && target > 0 && deadline != null) {
                  if (!isFinancial) {
                    final now = DateTime.now();
                    final from = DateTime(now.year, now.month, now.day);
                    final to = DateTime(deadline!.year, deadline!.month, deadline!.day);
                    int days = to.difference(from).inDays;
                    if (days <= 0) days = 1;
                    if (target / days < 1.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.get(ref, 'goal_not_approved') ?? 'Hedef Onaylanmadı: İlerleme hedeflerinde günlük hedef en az 1 adet olmalıdır. Lütfen daha yakın bir tarih seçin veya hedef adedini artırın.'),
                          backgroundColor: Colors.redAccent,
                        )
                      );
                      return;
                    }
                  }
                  ref.read(goalProvider.notifier).editGoal(goal.id, title, target, deadline!, isFinancial: isFinancial, currency: selectedCurrency);
                  Navigator.pop(context);
                }
              },
              child: Text(AppStrings.get(ref, 'edit') ?? 'Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
