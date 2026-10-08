import 'package:hive/hive.dart';
import 'package:finance_27/models/goal_deposit_model.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 3)
class GoalModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final double targetAmount;
  @HiveField(3)
  final double currentAmount;
  @HiveField(4)
  final DateTime deadline;
  @HiveField(5, defaultValue: [])
  final List<GoalDepositModel> deposits;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime? completedAt;
  @HiveField(8, defaultValue: true)
  final bool isFinancial;
  @HiveField(9)
  final String? currency;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.deposits = const [],
    DateTime? createdAt,
    this.completedAt,
    this.isFinancial = true,
    this.currency,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => targetAmount - currentAmount;
  
  int get remainingDays {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = to.difference(from).inDays;
    return difference > 0 ? difference : 0;
  }

  double get requiredDailySaving {
    final days = remainingDays;
    if (days <= 0) return remainingAmount;
    return remainingAmount / days;
  }

  GoalModel copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    List<GoalDepositModel>? deposits,
    DateTime? completedAt,
    bool? isFinancial,
    String? currency,
  }) {
    return GoalModel(
      id: this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      deposits: deposits ?? this.deposits,
      createdAt: this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isFinancial: isFinancial ?? this.isFinancial,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'deposits': deposits.map((d) => d.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isFinancial': isFinancial,
      'currency': currency,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String docId) {
    return GoalModel(
      id: docId,
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : DateTime.now(),
      deposits: (map['deposits'] as List?)?.map((x) => GoalDepositModel.fromMap(x as Map<String, dynamic>)).toList() ?? [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      isFinancial: map['isFinancial'] ?? true,
      currency: map['currency'],
    );
  }
}
