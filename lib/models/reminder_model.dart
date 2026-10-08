import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 7)
class ReminderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final String timeText;

  @HiveField(4)
  final String recurrence; // 'none', '1_day', '7_days', '1_month', '2_months'

  @HiveField(5, defaultValue: false)
  final bool isCompleted;

  ReminderModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.timeText,
    required this.recurrence,
    this.isCompleted = false,
  });

  ReminderModel copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    String? timeText,
    String? recurrence,
    bool? isCompleted,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      timeText: timeText ?? this.timeText,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startDate': startDate.toIso8601String(),
      'timeText': timeText,
      'recurrence': recurrence,
      'isCompleted': isCompleted,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id: docId,
      title: map['title'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      timeText: map['timeText'] ?? '',
      recurrence: map['recurrence'] ?? 'none',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
