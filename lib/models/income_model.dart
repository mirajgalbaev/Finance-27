import 'package:hive/hive.dart';

part 'income_model.g.dart';

@HiveType(typeId: 5)
class IncomeModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3, defaultValue: 'Income')
  final String title;
  @HiveField(4, defaultValue: 'USD')
  final String currency;

  IncomeModel({
    required this.id,
    required this.amount,
    required this.date,
    this.title = 'Income',
    this.currency = 'USD',
  });

  IncomeModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? title,
    String? currency,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      title: title ?? this.title,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'title': title,
      'currency': currency,
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map, String docId) {
    return IncomeModel(
      id: docId,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      title: map['title'] ?? 'Income',
      currency: map['currency'] ?? 'USD',
    );
  }
}
