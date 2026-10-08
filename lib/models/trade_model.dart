import 'package:hive/hive.dart';

part 'trade_model.g.dart';

@HiveType(typeId: 9)
class TradeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String timeText;

  @HiveField(3)
  final String exchange;

  @HiveField(4)
  final String market; // 'Spot', 'Futures'

  @HiveField(5)
  final String pair; // e.g., 'BTC/USDT'

  @HiveField(6)
  final String type; // 'Long', 'Short', 'Alış', 'Satış'

  @HiveField(7)
  final String leverage; // e.g., '10x', '1x'

  @HiveField(8)
  final double capitalAllocated;

  @HiveField(9)
  final double entryPrice;

  @HiveField(10)
  final double? exitPrice;

  @HiveField(11)
  final double? stopLoss;

  @HiveField(12)
  final double? takeProfit;

  @HiveField(13)
  final double? pnlPercent;

  @HiveField(14)
  final double? pnlAmount;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final DateTime? exitDate;

  @HiveField(17)
  final List<double>? takeProfits;

  @HiveField(18)
  final List<double>? buyTargets;

  @HiveField(19)
  final List<double>? sellTargets;

  TradeModel({
    required this.id,
    required this.date,
    required this.timeText,
    required this.exchange,
    required this.market,
    required this.pair,
    required this.type,
    required this.leverage,
    required this.capitalAllocated,
    required this.entryPrice,
    this.exitPrice,
    this.stopLoss,
    this.takeProfit,
    this.takeProfits,
    this.buyTargets,
    this.sellTargets,
    this.pnlPercent,
    this.pnlAmount,
    this.notes,
    this.exitDate,
  });

  TradeModel copyWith({
    String? id,
    DateTime? date,
    String? timeText,
    String? exchange,
    String? market,
    String? pair,
    String? type,
    String? leverage,
    double? capitalAllocated,
    double? entryPrice,
    double? exitPrice,
    double? stopLoss,
    double? takeProfit,
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,
    double? pnlPercent,
    double? pnlAmount,
    String? notes,
    DateTime? exitDate,
  }) {
    return TradeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      timeText: timeText ?? this.timeText,
      exchange: exchange ?? this.exchange,
      market: market ?? this.market,
      pair: pair ?? this.pair,
      type: type ?? this.type,
      leverage: leverage ?? this.leverage,
      capitalAllocated: capitalAllocated ?? this.capitalAllocated,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      takeProfits: takeProfits ?? this.takeProfits,
      buyTargets: buyTargets ?? this.buyTargets,
      sellTargets: sellTargets ?? this.sellTargets,
      pnlPercent: pnlPercent ?? this.pnlPercent,
      pnlAmount: pnlAmount ?? this.pnlAmount,
      notes: notes ?? this.notes,
      exitDate: exitDate ?? this.exitDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'timeText': timeText,
      'exchange': exchange,
      'market': market,
      'pair': pair,
      'type': type,
      'leverage': leverage,
      'capitalAllocated': capitalAllocated,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'takeProfits': takeProfits,
      'buyTargets': buyTargets,
      'sellTargets': sellTargets,
      'pnlPercent': pnlPercent,
      'pnlAmount': pnlAmount,
      'notes': notes,
      'exitDate': exitDate?.toIso8601String(),
    };
  }

  factory TradeModel.fromMap(Map<String, dynamic> map, String docId) {
    return TradeModel(
      id: docId,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      timeText: map['timeText'] ?? '',
      exchange: map['exchange'] ?? '',
      market: map['market'] ?? '',
      pair: map['pair'] ?? '',
      type: map['type'] ?? '',
      leverage: map['leverage'] ?? '',
      capitalAllocated: (map['capitalAllocated'] as num?)?.toDouble() ?? 0.0,
      entryPrice: (map['entryPrice'] as num?)?.toDouble() ?? 0.0,
      exitPrice: (map['exitPrice'] as num?)?.toDouble(),
      stopLoss: (map['stopLoss'] as num?)?.toDouble(),
      takeProfit: (map['takeProfit'] as num?)?.toDouble(),
      takeProfits: (map['takeProfits'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      buyTargets: (map['buyTargets'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      sellTargets: (map['sellTargets'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      pnlPercent: (map['pnlPercent'] as num?)?.toDouble(),
      pnlAmount: (map['pnlAmount'] as num?)?.toDouble(),
      notes: map['notes'],
      exitDate: map['exitDate'] != null ? DateTime.parse(map['exitDate']) : null,
    );
  }
}
