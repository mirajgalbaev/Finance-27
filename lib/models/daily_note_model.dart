import 'package:hive/hive.dart';

part 'daily_note_model.g.dart';

@HiveType(typeId: 8)
class DailyNoteModel extends HiveObject {
  @HiveField(0)
  final String dateKey; // Format: yyyy-MM-dd

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime updatedAt;

  DailyNoteModel({
    required this.dateKey,
    required this.text,
    required this.updatedAt,
  });

  DailyNoteModel copyWith({
    String? dateKey,
    String? text,
    DateTime? updatedAt,
  }) {
    return DailyNoteModel(
      dateKey: dateKey ?? this.dateKey,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyNoteModel.fromMap(Map<String, dynamic> map, String docId) {
    return DailyNoteModel(
      dateKey: map['dateKey'] ?? docId,
      text: map['text'] ?? '',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}
