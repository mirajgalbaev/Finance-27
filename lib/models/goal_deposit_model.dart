import 'package:hive/hive.dart';

part 'goal_deposit_model.g.dart';

@HiveType(typeId: 6)
class GoalDepositModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3, defaultValue: 'Deposit')
  final String title;

  GoalDepositModel({
    required this.id,
    required this.amount,
    required this.date,
    this.title = 'Deposit',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'title': title,
    };
  }

  factory GoalDepositModel.fromMap(Map<String, dynamic> map) {
    return GoalDepositModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      title: map['title'] ?? 'Deposit',
    );
  }
}
