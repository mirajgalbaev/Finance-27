import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 2)
class TaskModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final bool isCompleted;
  @HiveField(3)
  final double financialOutcome; // e.g., +$20 savings
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String? category;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.financialOutcome = 0.0,
    required this.date,
    this.category,
  });

  TaskModel copyWith({
    String? title,
    bool? isCompleted,
    double? financialOutcome,
    DateTime? date,
    String? category,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      financialOutcome: financialOutcome ?? this.financialOutcome,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'financialOutcome': financialOutcome,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      financialOutcome: (map['financialOutcome'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: map['category'],
    );
  }
}
