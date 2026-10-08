import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/providers/task_provider.dart';
import 'package:finance_27/providers/discipline_provider.dart';
import 'package:finance_27/providers/income_provider.dart';
import 'package:finance_27/providers/goal_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/providers/trade_provider.dart';
import 'package:finance_27/providers/daily_note_provider.dart';
import 'package:finance_27/providers/reminder_provider.dart';
import 'package:finance_27/models/task_model.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/models/transaction_model.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/ui/widgets/jar_card.dart';
import 'package:finance_27/ui/widgets/jar_chart.dart';
import 'package:finance_27/ui/widgets/rollover_summary_widget.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/core/quotes_data.dart';
import 'package:finance_27/providers/monthly_stats_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:finance_27/ui/screens/jar_detail_screen.dart';
import 'package:finance_27/ui/screens/goal_detail_screen.dart';
import 'package:finance_27/ui/screens/main_shell.dart';
import 'package:finance_27/ui/screens/splash_screen.dart';
import 'package:finance_27/ui/screens/auth_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final jars = ref.watch(jarProvider).where((j) => j.isActive).toList();
    final incomes = ref.watch(incomeProvider);
    final activeGoals = ref.watch(goalProvider).where((g) => g.currentAmount < g.targetAmount).toList();
    final monthlyStats = ref.watch(monthlyStatsProvider);
    
    final theme = Theme.of(context);
    final selectedCurrency = ref.watch(currencyProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: selectedCurrency);

    return Scaffold(
      drawer: const _ProfileDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            centerTitle: true,
            leadingWidth: 160,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                children: [
                  _buildProfileAvatar(context, ref),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.watch(authProvider).currentUser?.name ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ref.watch(authProvider).currentUser?.email?.split('@').first ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            title: const Text(
              'Kundoluk 27',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orange, size: 28),
                onPressed: () => _showResetConfirmationDialog(context, ref),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.language, color: Colors.white, size: 28),
                    onSelected: (String langCode) => ref.read(localeProvider.notifier).state = langCode,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'en', child: Text('English')),
                      const PopupMenuItem(value: 'tr', child: Text('Türkçe')),
                      const PopupMenuItem(value: 'ru', child: Text('Русский')),
                      const PopupMenuItem(value: 'kg', child: Text('Кыргызча')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMentorCard(context, ref),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSectionHeader(context, AppStrings.get(ref, 'jar_status')),
                    _buildMonthSelector(context, ref),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 20),
                JarDistributionChart(
                  jars: jars, 
                  monthlyStats: monthlyStats,
                  actionArea: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RolloverSummaryWidget(),
                      const SizedBox(height: 16),
                      _buildSectionHeader(context, AppStrings.get(ref, 'monthly_income')),
                      const SizedBox(height: 16),
                      _buildMonthlyIncomeActions(context, ref),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMonthlyIncomeSummary(context, ref),
                const SizedBox(height: 24),
                _buildSectionHeader(context, AppStrings.get(ref, 'goals') ?? 'Goals'),
                const SizedBox(height: 16),
                _buildGoalsSummary(context, ref),
                const SizedBox(height: 24),
                _buildSectionHeader(context, AppStrings.get(ref, 'quick_budgets')),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final jar = jars[index];
                  
                  return JarCard(
                    jar: jar,
                    currentMonthBalances: monthlyStats.jarBalances[jar.type],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JarDetailScreen(
                          jarType: jar.type,
                        ),
                      ),
                    ),
                  );
                },
                childCount: jars.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      )
    );
  }

  Widget _buildProfileAvatar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final theme = Theme.of(context);
    
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.primaryColor, width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: theme.cardColor,
          backgroundImage: user?.profileImagePath != null 
              ? (user!.profileImagePath!.startsWith('data:image')
                  ? MemoryImage(base64Decode(user.profileImagePath!.split(',').last)) as ImageProvider
                  : (user.profileImagePath!.startsWith('http') 
                      ? NetworkImage(user.profileImagePath!) as ImageProvider 
                      : FileImage(File(user.profileImagePath!))))
              : null,
          child: user?.profileImagePath == null 
              ? Icon(Icons.person, color: theme.primaryColor, size: 20)
              : null,
        ),
      ),
    ));
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final period = ref.watch(jarStatusPeriodProvider);
    final theme = Theme.of(context);
    final localeCode = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    
    String dateDisplay = '';
    if (period == JarStatusPeriod.monthly) {
      dateDisplay = DateFormat.yMMMM(AppStrings.getDateFormatLocale(localeCode)).format(selectedMonth).toUpperCase();
    } else if (period == JarStatusPeriod.yearly) {
      dateDisplay = DateFormat.y(AppStrings.getDateFormatLocale(localeCode)).format(selectedMonth);
    } else {
      dateDisplay = AppStrings.get(ref, 'all_time_lifetime') ?? 'LIFETIME';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (period != JarStatusPeriod.lifetime)
            InkWell(
              onTap: () {
                ref.read(selectedMonthProvider.notifier).update((state) {
                  if (period == JarStatusPeriod.yearly) return DateTime(state.year - 1, state.month, 1);
                  return DateTime(state.year, state.month - 1, 1);
                });
              },
              child: Icon(Icons.chevron_left, color: theme.primaryColor, size: 28),
            ),
          
          if (period != JarStatusPeriod.lifetime) const SizedBox(width: 8),

          InkWell(
            onTap: period == JarStatusPeriod.lifetime ? null : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state = DateTime(picked.year, picked.month, 1);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                ),
                if (period != JarStatusPeriod.lifetime) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.calendar_month, size: 18, color: theme.primaryColor),
                ],
              ],
            ),
          ),

          if (period != JarStatusPeriod.lifetime) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ref.read(selectedMonthProvider.notifier).update((state) {
                  if (period == JarStatusPeriod.yearly) return DateTime(state.year + 1, state.month, 1);
                  return DateTime(state.year, state.month + 1, 1);
                });
              },
              child: Icon(Icons.chevron_right, color: theme.primaryColor, size: 28),
            ),
          ],
          
          Container(
            height: 24,
            width: 1.5,
            color: theme.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<JarStatusPeriod>(
              value: period,
              icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              isDense: true,
              onChanged: (val) {
                if (val != null) ref.read(jarStatusPeriodProvider.notifier).state = val;
              },
              items: [
                DropdownMenuItem(
                  value: JarStatusPeriod.monthly,
                  child: Text(AppStrings.get(ref, 'monthly') ?? 'Monthly'),
                ),
                DropdownMenuItem(
                  value: JarStatusPeriod.yearly,
                  child: Text(AppStrings.get(ref, 'yearly') ?? 'Yearly'),
                ),
                DropdownMenuItem(
                  value: JarStatusPeriod.lifetime,
                  child: Text(AppStrings.get(ref, 'all_time_lifetime') ?? 'Lifetime'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(BuildContext context, WidgetRef ref) {
    final discipline = ref.watch(disciplineProvider);
    final theme = Theme.of(context);

    String displayMessage;
    if (discipline.mentorMessage == 'mentor_set_goal' || discipline.mentorMessage == 'mentor_on_track') {
      final quoteIndex = ref.watch(randomQuoteIndexProvider);
      displayMessage = QuotesData.getQuote(ref.watch(localeProvider) ?? 'tr', quoteIndex);
    } else {
      displayMessage = AppStrings.get(ref, discipline.mentorMessage);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: discipline.isWarning 
            ? Colors.red.withOpacity(0.2) 
            : theme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: discipline.isWarning ? Colors.red : theme.primaryColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            discipline.isWarning ? Icons.warning_amber : Icons.tips_and_updates,
            color: discipline.isWarning ? Colors.red : theme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildGoalsSummary(BuildContext context, WidgetRef ref) {
    final currencySymbol = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider)).currencySymbol;
    final goals = ref.watch(goalProvider);
    final activeFinGoals = goals.where((g) => g.currentAmount < g.targetAmount && g.isFinancial).toList();
    final activeProgGoals = goals.where((g) => g.currentAmount < g.targetAmount && !g.isFinancial).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'goals') ?? 'Goals',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => ref.read(tabProvider.notifier).state = 3,
                child: Text(AppStrings.get(ref, 'tab_goals') ?? 'See All'),
              ),
            ],
          ),
          if (activeFinGoals.isEmpty && activeProgGoals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, color: Theme.of(context).primaryColor, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppStrings.get(ref, 'no_active_goals') ?? 'No active goals in progress. Time to set new targets!',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (activeFinGoals.isNotEmpty) ...[
               const SizedBox(height: 8),
               Text(AppStrings.get(ref, 'active_fin_goals') ?? 'Finansal Hedefler', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
               const SizedBox(height: 8),
               _buildActiveGoalsList(context, ref, activeFinGoals, currencySymbol),
            ],
            if (activeProgGoals.isNotEmpty) ...[
               const SizedBox(height: 16),
               Text(AppStrings.get(ref, 'prog_goal_label') ?? 'İlerleme Hedefleri (Kişisel Gelişim)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
               const SizedBox(height: 8),
               _buildActiveGoalsList(context, ref, activeProgGoals, currencySymbol),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildActiveGoalsList(BuildContext context, WidgetRef ref, List<GoalModel> activeGoals, String currencySymbol) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
        itemCount: activeGoals.length > 3 ? 3 : activeGoals.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final goal = activeGoals[index];
          final goalCurrencySymbol = goal.currency != null ? NumberFormat.simpleCurrency(name: goal.currency).currencySymbol : currencySymbol;
          final progress = (goal.targetAmount > 0) ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
          
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goal.id)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.isFinancial
                          ? '${goalCurrencySymbol}${goal.currentAmount.toStringAsFixed(0)} / ${goalCurrencySymbol}${goal.targetAmount.toStringAsFixed(0)}'
                          : '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)} ${AppStrings.get(ref, 'units') ?? 'Adet'}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '${AppStrings.get(ref, 'deadline') ?? 'Deadline'}: ${DateFormat.yMMMd(AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(goal.deadline)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.isFinancial
                      ? '${AppStrings.get(ref, 'daily_target') ?? 'Daily'}: $goalCurrencySymbol${goal.requiredDailySaving.toStringAsFixed(0)} • ${AppStrings.get(ref, 'monthly_target') ?? 'Monthly'}: $goalCurrencySymbol${(goal.requiredDailySaving * 30).toStringAsFixed(0)}'
                      : '${AppStrings.get(ref, 'daily_target') ?? 'Daily'}: ${goal.requiredDailySaving.toStringAsFixed(0)} ${AppStrings.get(ref, 'units') ?? 'Adet'} • ${AppStrings.get(ref, 'monthly_target') ?? 'Monthly'}: ${(goal.requiredDailySaving * 30).toStringAsFixed(0)} ${AppStrings.get(ref, 'units') ?? 'Adet'}',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildMonthlyIncomeActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            context,
            title: AppStrings.get(ref, 'distribute_income'),
            icon: Icons.account_balance_wallet,
            color: Colors.green,
            onTap: () => _showDistributeIncomeDialog(context, ref),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionTile(
            context,
            title: AppStrings.get(ref, 'edit_percentages'),
            icon: Icons.percent,
            color: Theme.of(context).primaryColor,
            isOutlined: true,
            onTap: () => _showEditPercentagesDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap, bool isOutlined = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isOutlined ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDistributeIncomeDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String title = '';
    double amount = 0.0;
    DateTime selectedDate = DateTime.now();
    String selectedCurrency = ref.read(currencyProvider);

    String getSymbol(String c) {
      switch (c) {
        case 'KGS': return 'с';
        case 'USD': return '\$';
        case 'EUR': return '€';
        case 'TRY': return '₺';
        case 'RUB': return '₽';
        default: return c;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                     child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       AppStrings.get(ref, 'distribute_income'),
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                   ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'source_optional') ?? 'Source (e.g. Salary)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: const Icon(Icons.label_outline, color: Colors.grey, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'amount'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8, top: 13),
                        child: Text(
                          getSymbol(selectedCurrency),
                          style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['KGS', 'USD', 'EUR', 'TRY', 'RUB'].contains(selectedCurrency) ? selectedCurrency : 'KGS',
                    dropdownColor: theme.cardColor,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'currency') ?? 'Para Birimi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: Icon(Icons.language, color: theme.primaryColor, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem(value: 'KGS', child: Text('KGS (с)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                      DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                      DropdownMenuItem(value: 'TRY', child: Text('TRY (₺)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                      DropdownMenuItem(value: 'RUB', child: Text('RUB (₽)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCurrency = val);
                        ref.read(currencyProvider.notifier).setCurrency(val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: theme.primaryColor,
                                onPrimary: Colors.white,
                                surface: theme.cardColor,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.get(ref, 'cancel'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (amount > 0) {
                      ref.read(incomeProvider.notifier).addIncome(amount, title, selectedCurrency, date: selectedDate);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(AppStrings.get(ref, 'confirm'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showAddJarDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final percentageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppStrings.get(ref, 'add_new_jar')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: nameController,
              decoration: InputDecoration(labelText: AppStrings.get(ref, 'jar_name')),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: percentageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: AppStrings.get(ref, 'percentage')),
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
              ref.read(jarProvider.notifier).addJar(nameController.text.trim(), (double.tryParse(percentageController.text) ?? 0) / 100);
              Navigator.pop(context);
              _showEditPercentagesDialog(context, ref);
            },
            child: Text(AppStrings.get(ref, 'add')),
          ),
        ],
      ),
    );
  }

  void _showEditPercentagesDialog(BuildContext context, WidgetRef ref) {
    final jars = ref.read(jarProvider).where((j) => j.isActive).toList();
    Map<JarType, double> editedPercentages = {
      for (var jar in jars) jar.type: jar.allocationPercentage
    };
    Map<JarType, String?> editedNames = {
      for (var jar in jars) jar.type: jar.customName
    };
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final total = editedPercentages.values.fold(0.0, (sum, p) => sum + p);
          final isValid = total >= 0.99 && total <= 1.01;

          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            title: Row(
              children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.15), shape: BoxShape.circle),
                   child: Icon(Icons.percent, color: theme.primaryColor, size: 20),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     AppStrings.get(ref, 'edit_percentages'),
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                 ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.get(ref, 'invalid_allocations'),
                            style: TextStyle(
                              color: isValid ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${AppStrings.get(ref, 'total')}: ${(total * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isValid ? Colors.green : Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...editedPercentages.keys.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: editedNames[type],
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: AppStrings.get(ref, type.displayName),
                                  icon: Icon(_getIconForJarType(type), color: theme.primaryColor, size: 16),
                                  suffixIcon: const Icon(Icons.edit, size: 12, color: Colors.grey),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                onChanged: (val) {
                                  editedNames[type] = val.trim().isEmpty ? null : val.trim();
                                },
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.withOpacity(0.2),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            SizedBox(
                              width: 45,
                              child: TextFormField(
                                initialValue: (editedPercentages[type]! * 100).toStringAsFixed(0),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.primaryColor),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  suffixText: '%',
                                  suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null) {
                                    setState(() {
                                      editedPercentages[type] = parsed / 100.0;
                                    });
                                  }
                                },
                              ),
                            ),
                            if (editedPercentages.length > 1) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  ref.read(jarProvider.notifier).deleteJar(type);
                                  Navigator.pop(context);
                                  _showEditPercentagesDialog(context, ref);
                                },
                                child: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  if (editedPercentages.length < 6) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppStrings.get(ref, 'add_new_jar')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        foregroundColor: theme.primaryColor,
                        elevation: 0,
                      ),
                      onPressed: () {
                         Navigator.pop(context);
                         _showAddJarDialog(context, ref);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.grey),
                tooltip: 'Fabrika Ayarlarına Dön / Reset All',
                onPressed: () {
                   ref.read(jarProvider.notifier).reset();
                   Navigator.pop(context);
                   _showEditPercentagesDialog(context, ref);
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.get(ref, 'cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isValid ? () {
                      ref.read(jarProvider.notifier).savePercentagesAndNames(editedPercentages, editedNames);
                      Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(backgroundColor: isValid ? theme.primaryColor : Colors.grey),
                    child: Text(AppStrings.get(ref, 'save')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForJarType(JarType type) {
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

  Widget _buildMonthlyIncomeSummary(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allIncomes = ref.watch(incomeProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final period = ref.watch(jarStatusPeriodProvider);
    
    // Filter by period
    final monthIncomes = allIncomes.where((i) {
      if (period == JarStatusPeriod.monthly) {
        return i.date.month == selectedMonth.month && i.date.year == selectedMonth.year;
      } else if (period == JarStatusPeriod.yearly) {
        return i.date.year == selectedMonth.year;
      } else {
        return true;
      }
    }).toList();

    String periodTotalLabel = AppStrings.get(ref, 'monthly_total') ?? 'Aylık Toplam';
    if (period == JarStatusPeriod.yearly) {
      periodTotalLabel = AppStrings.get(ref, 'yearly_total') ?? 'Yıllık Toplam';
    } else if (period == JarStatusPeriod.lifetime) {
      periodTotalLabel = AppStrings.get(ref, 'lifetime_total') ?? 'Tüm Zamanlar Toplam';
    }
    
    if (monthIncomes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            AppStrings.get(ref, 'no_income_this_month') ?? 'Bu ay için henüz gelir kaydedilmedi.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Group by currency
    final groupedIncomes = <String, List<dynamic>>{};
    for (var income in monthIncomes) {
      groupedIncomes.putIfAbsent(income.currency, () => []).add(income);
    }

    return Column(
      children: groupedIncomes.entries.map((entry) {
        final currency = entry.key;
        final incomesForCurrency = entry.value;
        final currencySymbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;
        final totalAmount = incomesForCurrency.fold(0.0, (sum, item) => sum + item.amount);

        return Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          periodTotalLabel,
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$currencySymbol${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                  ),
                ],
              ),
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: incomesForCurrency.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 40, endIndent: 16),
                  itemBuilder: (context, index) {
                    final income = incomesForCurrency[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 40, right: 4),
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        income.title,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white70),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(income.date),
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+ $currencySymbol${income.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showEditIncomeDialog(context, ref, income),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref.read(incomeProvider.notifier).deleteIncome(income.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEditIncomeDialog(BuildContext context, WidgetRef ref, dynamic income) {
    double updatedAmount = income.amount;
    String updatedTitle = income.title;
    String selectedCurrency = income.currency;
    DateTime selectedDate = income.date;
    final theme = Theme.of(context);

    String getSymbol(String c) {
      switch (c) {
        case 'KGS': return 'с';
        case 'USD': return '\$';
        case 'EUR': return '€';
        case 'TRY': return '₺';
        case 'RUB': return '₽';
        default: return c;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text('${AppStrings.get(ref, 'edit')}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    initialValue: updatedTitle,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(ref, 'source_optional') ?? 'Source (e.g. Salary)',
                    ),
                    onChanged: (value) => updatedTitle = value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: updatedAmount.toStringAsFixed(2),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppStrings.get(ref, 'amount'),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 8, top: 13),
                              child: Text(
                                getSymbol(selectedCurrency),
                                style: TextStyle(color: theme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          ),
                          onChanged: (value) => updatedAmount = double.tryParse(value) ?? updatedAmount,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCurrency,
                            items: [
                              DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                              DropdownMenuItem(value: 'TRY', child: Text('TRY (₺)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                              DropdownMenuItem(value: 'RUB', child: Text('RUB (₽)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
                              DropdownMenuItem(value: 'KGS', child: Text('KGS (с)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor))),
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: theme.primaryColor,
                                onPrimary: Colors.white,
                                surface: theme.cardColor,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.get(ref, 'cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(incomeProvider.notifier).editIncome(income.id, updatedAmount, updatedTitle, selectedCurrency, newDate: selectedDate);
                    Navigator.pop(context);
                  },
                  child: Text(AppStrings.get(ref, 'save')),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppStrings.get(ref, 'reset_all_data'), style: const TextStyle(color: Colors.redAccent)),
        content: Text(AppStrings.get(ref, 'reset_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get(ref, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(jarProvider.notifier).reset();
              ref.read(taskProvider.notifier).reset();
              ref.read(goalProvider.notifier).reset();
              ref.read(transactionProvider.notifier).reset();
              ref.read(incomeProvider.notifier).reset();
              ref.read(tradeProvider.notifier).reset();
              ref.read(dailyNoteProvider.notifier).reset();
              ref.read(reminderProvider.notifier).reset();
              ref.read(currencyProvider.notifier).reset();
              // Do NOT reset authProvider, so the account stays logged in.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
              );
            },
            child: Text(AppStrings.get(ref, 'confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileDrawer extends ConsumerWidget {
  const _ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        color: theme.scaffoldBackgroundColor,
        child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                bool isDesktop = false;
                if (!kIsWeb) {
                  isDesktop = defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux;
                }

                if (isDesktop) {
                  // image_cropper is not supported natively on desktop platforms yet
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Kırpma özelliği masaüstü platformlarında desteklenmiyor, resim yükleniyor...'),
                    ));
                  }
                  final success = await ref.read(authProvider.notifier).updateProfileImage(xFile: pickedFile);
                  if (!success && context.mounted) {
                    final error = ref.read(authProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error ?? 'Resim yüklenemedi. (Firebase Storage aktif mi?)'),
                      backgroundColor: Colors.red,
                    ));
                  }
                  return;
                }

                try {
                  final croppedFile = await ImageCropper().cropImage(
                    sourcePath: pickedFile.path,
                    compressQuality: 60,
                    maxWidth: 400,
                    maxHeight: 400,
                    uiSettings: [
                      AndroidUiSettings(
                          toolbarTitle: AppStrings.get(ref, 'crop_image') ?? 'Fotoğrafı Kırp',
                          toolbarColor: Colors.deepOrange,
                          toolbarWidgetColor: Colors.white,
                          initAspectRatio: CropAspectRatioPreset.square,
                          lockAspectRatio: true),
                      IOSUiSettings(
                        title: 'Fotoğrafı Kırp',
                        aspectRatioLockEnabled: true,
                        resetAspectRatioEnabled: false,
                        aspectRatioPickerButtonHidden: true,
                      ),
                      WebUiSettings(
                        context: context,
                        presentStyle: WebPresentStyle.page,
                      ),
                    ],
                  );
                  if (croppedFile != null) {
                    bool success = false;
                    if (kIsWeb) {
                        final bytes = await croppedFile.readAsBytes();
                        final base64String = base64Encode(bytes);
                        final finalPath = 'data:image/jpeg;base64,$base64String';
                        success = await ref.read(authProvider.notifier).updateProfileImage(imagePath: finalPath);
                    } else {
                        success = await ref.read(authProvider.notifier).updateProfileImage(imagePath: croppedFile.path);
                    }
                    if (!success && context.mounted) {
                        final error = ref.read(authProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error ?? 'Resim yüklenemedi.'),
                          backgroundColor: Colors.red,
                        ));
                    }
                  }
                } catch (e) {
                  await ref.read(authProvider.notifier).updateProfileImage(xFile: pickedFile);
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor, width: 3),
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.cardColor,
                backgroundImage: user?.profileImagePath != null 
                    ? (user!.profileImagePath!.startsWith('data:image')
                        ? MemoryImage(base64Decode(user.profileImagePath!.split(',').last)) as ImageProvider
                        : (user.profileImagePath!.startsWith('http') 
                            ? NetworkImage(user.profileImagePath!) as ImageProvider 
                            : FileImage(File(user.profileImagePath!))))
                    : null,
                child: user?.profileImagePath == null 
                    ? Icon(Icons.add_a_photo, color: theme.primaryColor, size: 40)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user?.name ?? 'Kullanıcı',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  String newName = user?.name ?? '';
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('İsmi Düzenle'),
                      content: TextFormField(
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Yeni İsim'),
                        onChanged: (val) => newName = val,
                        initialValue: newName,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (newName.trim().isNotEmpty) {
                              ref.read(authProvider.notifier).updateName(newName.trim());
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Kaydet'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(AppStrings.get(ref, 'logout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ));
  }
}
