import 'package:hive/hive.dart';
import 'package:finance_27/models/jar_model.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 4)
class TransactionModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final bool isIncome;
  @HiveField(4)
  final JarType jarType;
  @HiveField(5, defaultValue: 'Transaction')
  final String title;
  @HiveField(6, defaultValue: 'USD')
  final String currency;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.jarType,
    this.title = 'Transaction',
    this.currency = 'USD',
  });

  TransactionModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    bool? isIncome,
    JarType? jarType,
    String? title,
    String? currency,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      jarType: jarType ?? this.jarType,
      title: title ?? this.title,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'jarType': jarType.name,
      'title': title,
      'currency': currency,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TransactionModel(
      id: docId,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      isIncome: map['isIncome'] ?? false,
      jarType: JarType.values.firstWhere((e) => e.name == map['jarType'], orElse: () => JarType.necessities),
      title: map['title'] ?? 'Transaction',
      currency: map['currency'] ?? 'USD',
    );
  }
}
