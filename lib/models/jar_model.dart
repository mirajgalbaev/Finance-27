import 'package:hive/hive.dart';

part 'jar_model.g.dart';

@HiveType(typeId: 0)
enum JarType {
  @HiveField(0)
  necessities,
  @HiveField(1)
  financialFreedom,
  @HiveField(2)
  longTermSavings,
  @HiveField(3)
  education,
  @HiveField(4)
  play,
  @HiveField(5)
  giving,
}

extension JarTypeExtension on JarType {
  String get displayName {
    switch (this) {
      case JarType.necessities:
        return 'necessities';
      case JarType.financialFreedom:
        return 'financial_freedom';
      case JarType.longTermSavings:
        return 'long_term_savings';
      case JarType.education:
        return 'education';
      case JarType.play:
        return 'play';
      case JarType.giving:
        return 'giving';
    }
  }

  double get percentage {
    switch (this) {
      case JarType.necessities:
        return 0.55;
      case JarType.financialFreedom:
        return 0.10;
      case JarType.longTermSavings:
        return 0.10;
      case JarType.education:
        return 0.10;
      case JarType.play:
        return 0.10;
      case JarType.giving:
        return 0.05;
    }
  }

  int get sortOrder {
    switch (this) {
      case JarType.necessities: return 1;
      case JarType.financialFreedom: return 2;
      case JarType.education: return 3;
      case JarType.longTermSavings: return 4;
      case JarType.play: return 5;
      case JarType.giving: return 6;
    }
  }
}

@HiveType(typeId: 1)
class JarModel {
  @HiveField(0)
  final JarType type;
  @HiveField(1)
  final Map<String, double> balances;
  @HiveField(2)
  final double? customPercentage;
  @HiveField(3)
  final String? customName;
  @HiveField(4, defaultValue: true)
  final bool isActive;

  double get allocationPercentage => customPercentage ?? type.percentage;

  JarModel({
    required this.type,
    Map<String, double>? balances,
    this.customPercentage,
    this.customName,
    this.isActive = true,
  }) : balances = balances ?? {};

  JarModel copyWith({
    Map<String, double>? balances,
    double? customPercentage,
    String? customName,
    bool clearCustomName = false,
    bool? isActive,
  }) {
    return JarModel(
      type: type,
      balances: balances ?? Map.from(this.balances),
      customPercentage: customPercentage ?? this.customPercentage,
      customName: clearCustomName ? null : (customName ?? this.customName),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'balances': balances,
      'customPercentage': customPercentage,
      'customName': customName,
      'isActive': isActive,
    };
  }

  factory JarModel.fromMap(Map<String, dynamic> map) {
    String? parsedName = map['customName'];
    if (parsedName != null) {
      final lower = parsedName.toLowerCase().trim();
      const defaultNames = [
        'ihtiyaçlar', 'i̇htiyaçlar', 'necessities', 'потребности',
        'finansal özgürlük', 'financial freedom', 'финансовая свобода',
        'uzun vadeli birikim', 'long-term savings', 'долгосрочные сбережения',
        'eğitim', 'education', 'образование',
        'oyun/eğlence', 'play/fun', 'развлечения',
        'bağış/yardım', 'giving', 'благотворительность'
      ];
      if (defaultNames.contains(lower)) {
        parsedName = null;
      }
    }
    return JarModel(
      type: JarType.values[map['type'] as int],
      balances: Map<String, double>.from(map['balances'] ?? {}),
      customPercentage: (map['customPercentage'] as num?)?.toDouble(),
      customName: parsedName,
      isActive: map['isActive'] ?? true,
    );
  }
}
