import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/providers/goal_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/models/jar_model.dart';

final disciplineProvider = Provider((ref) {
  final goals = ref.watch(goalProvider);
  final jars = ref.watch(jarProvider);
  final transactions = ref.watch(transactionProvider);

  if (goals.isEmpty) {
    return DisciplineState(
      mentorMessage: 'mentor_set_goal',
      dailyLimit: 0,
    );
  }

  // Calculate daily limit based on the first goal for simplicity
  final goal = goals.first;
  final dailyRequiredSaving = goal.requiredDailySaving;
  
  // Logic: Today's spending in 'fun' and 'necessities' jars
  final today = DateTime.now();
  final todaySpending = transactions.where((t) => 
    !t.isIncome && 
    t.date.year == today.year && 
    t.date.month == today.month && 
    t.date.day == today.day &&
    (t.jarType == JarType.necessities || t.jarType == JarType.play)
  ).fold(0.0, (sum, t) => sum + t.amount);

  // Mentor Logic
  String message = 'mentor_on_track';
  bool isWarning = false;

  if (goal.remainingDays < 7 && goal.remainingAmount > 100) {
    message = 'mentor_critical';
    isWarning = true;
  }

  return DisciplineState(
    mentorMessage: message,
    dailyLimit: dailyRequiredSaving,
    isWarning: isWarning,
  );
});

class DisciplineState {
  final String mentorMessage;
  final double dailyLimit;
  final bool isWarning;

  DisciplineState({
    required this.mentorMessage,
    required this.dailyLimit,
    this.isWarning = false,
  });
}
