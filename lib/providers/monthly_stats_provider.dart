import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/providers/income_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/providers/jar_provider.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

enum JarStatusPeriod { monthly, yearly, lifetime }
final jarStatusPeriodProvider = StateProvider<JarStatusPeriod>((ref) => JarStatusPeriod.monthly);

final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final incomes = ref.watch(incomeProvider);
  final transactions = ref.watch(transactionProvider);
  final jars = ref.watch(jarProvider);
  
  final now = ref.watch(selectedMonthProvider);
  final period = ref.watch(jarStatusPeriodProvider);
  
  final currentMonthIncomes = <String, double>{};
  for (var i in incomes.where((i) {
    if (period == JarStatusPeriod.monthly) return i.date.month == now.month && i.date.year == now.year;
    if (period == JarStatusPeriod.yearly) return i.date.year == now.year;
    return true;
  })) {
    currentMonthIncomes[i.currency] = (currentMonthIncomes[i.currency] ?? 0.0) + i.amount;
  }

  final Map<JarType, Map<String, double>> currentMonthBalances = {};
  final Map<JarType, Map<String, double>> currentMonthJarIncomes = {};
  final Map<JarType, Map<String, double>> currentMonthJarExpenses = {};
  final Map<JarType, Map<String, double>> previousPeriodRollovers = {};
  final Map<String, double> currentMonthExpense = {};
  
  for (var jar in jars) {
    final periodTransactions = transactions.where((t) {
      if (t.jarType != jar.type) return false;
      if (period == JarStatusPeriod.monthly) return t.date.month == now.month && t.date.year == now.year;
      if (period == JarStatusPeriod.yearly) return t.date.year == now.year;
      return true;
    });

    final rolloverTransactions = transactions.where((t) {
      if (t.jarType != jar.type) return false;
      if (period == JarStatusPeriod.monthly) {
        return t.date.isBefore(DateTime(now.year, now.month, 1));
      } else if (period == JarStatusPeriod.yearly) {
        return t.date.isBefore(DateTime(now.year, 1, 1));
      }
      return false; // Lifetime has no rollover
    });

    final rolloverBalance = <String, double>{};
    for (var t in rolloverTransactions) {
      if (t.isIncome) {
         rolloverBalance[t.currency] = (rolloverBalance[t.currency] ?? 0.0) + t.amount;
      } else {
         rolloverBalance[t.currency] = (rolloverBalance[t.currency] ?? 0.0) - t.amount;
      }
    }

    final jarBalance = Map<String, double>.from(rolloverBalance);
    final jarIncome = <String, double>{};
    final jarExpense = <String, double>{};

    for (var t in periodTransactions) {
      if (t.isIncome) {
         jarBalance[t.currency] = (jarBalance[t.currency] ?? 0.0) + t.amount;
         jarIncome[t.currency] = (jarIncome[t.currency] ?? 0.0) + t.amount;
      } else {
         jarBalance[t.currency] = (jarBalance[t.currency] ?? 0.0) - t.amount;
         jarExpense[t.currency] = (jarExpense[t.currency] ?? 0.0) + t.amount;
         currentMonthExpense[t.currency] = (currentMonthExpense[t.currency] ?? 0.0) + t.amount;
      }
    }
    
    currentMonthBalances[jar.type] = jarBalance;
    currentMonthJarIncomes[jar.type] = jarIncome;
    currentMonthJarExpenses[jar.type] = jarExpense;
    previousPeriodRollovers[jar.type] = rolloverBalance;
  }

  return MonthlyStats(
    totalIncome: currentMonthIncomes,
    totalExpense: currentMonthExpense,
    jarBalances: currentMonthBalances,
    jarIncomes: currentMonthJarIncomes,
    jarExpenses: currentMonthJarExpenses,
    jarRollovers: previousPeriodRollovers,
  );
});

class MonthlyStats {
  final Map<String, double> totalIncome;
  final Map<String, double> totalExpense;
  final Map<JarType, Map<String, double>> jarBalances;
  final Map<JarType, Map<String, double>> jarIncomes;
  final Map<JarType, Map<String, double>> jarExpenses;
  final Map<JarType, Map<String, double>> jarRollovers;

  MonthlyStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.jarBalances,
    required this.jarIncomes,
    required this.jarExpenses,
    required this.jarRollovers,
  });
}
