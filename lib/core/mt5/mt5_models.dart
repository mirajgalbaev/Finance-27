enum MT5TradeDirection {
  buy,
  sell,
}

enum MT5RiskBase {
  balance,
  equity,
}

enum MT5CalcMode {
  forex,
  cfd,
  cfdIndex,
  cfdLeverage,
  futures,
  crypto,
  exchangeStocks,
}

enum CommissionType {
  perLot,
  perSide,
  roundTurn,
  percentage,
}

class CommissionModel {
  final CommissionType type;
  final double value;

  const CommissionModel({
    required this.type,
    required this.value,
  });
}

class SwapModel {
  final double longSwap;
  final double shortSwap;

  const SwapModel({
    required this.longSwap,
    required this.shortSwap,
  });
}

class MT5SymbolSpecification {
  final double contractSize;
  final double tickSize;
  final double tickValueProfit;
  final double tickValueLoss;
  final double volumeMin;
  final double volumeMax;
  final double volumeStep;
  final double stopsLevel; // In points
  final double freezeLevel; // In points
  final MT5CalcMode calcMode;
  final int digits;
  final double point;
  final String currencyBase;
  final String currencyProfit;
  final String currencyMargin;

  const MT5SymbolSpecification({
    required this.contractSize,
    required this.tickSize,
    required this.tickValueProfit,
    required this.tickValueLoss,
    required this.volumeMin,
    required this.volumeMax,
    required this.volumeStep,
    required this.stopsLevel,
    required this.freezeLevel,
    required this.calcMode,
    required this.digits,
    required this.point,
    required this.currencyBase,
    required this.currencyProfit,
    required this.currencyMargin,
  });
}

class TradeCalculationRequest {
  final String symbol;
  final MT5TradeDirection direction;
  final double entryPrice;
  final double stopLoss;
  final double? takeProfit; // Optional
  final double accountBalance;
  final double accountEquity;
  final MT5RiskBase riskBase;
  final double riskPercentage;
  final MT5SymbolSpecification symbolSpec;
  final CommissionModel? commission;
  final SwapModel? swap;
  final double leverage;

  const TradeCalculationRequest({
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    required this.stopLoss,
    this.takeProfit,
    required this.accountBalance,
    required this.accountEquity,
    required this.riskBase,
    required this.riskPercentage,
    required this.symbolSpec,
    this.commission,
    this.swap,
    required this.leverage,
  });
}

class TradeCalculationResult {
  final String symbol;
  final MT5TradeDirection direction;
  final double entryPrice;
  final double stopLoss;
  final double? takeProfit;
  final MT5RiskBase riskBase;
  final double riskPercentage;
  final double targetRiskAmount;
  final double rawLotSize;
  final double finalLotSize;
  final double actualRiskAmount;
  final double? potentialProfit;
  final double potentialLoss;
  final double? riskRewardRatio;
  final double commission;
  final double swap;
  final double requiredMargin;
  final double freeMargin;
  final double leverage;
  final double contractSize;
  final double tickSize;
  final double tickValue;
  final double volumeMin;
  final double volumeMax;
  final double volumeStep;
  final int priceDigits;
  final List<String> validationErrors;
  final List<String> warnings;

  const TradeCalculationResult({
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    required this.stopLoss,
    this.takeProfit,
    required this.riskBase,
    required this.riskPercentage,
    required this.targetRiskAmount,
    required this.rawLotSize,
    required this.finalLotSize,
    required this.actualRiskAmount,
    this.potentialProfit,
    required this.potentialLoss,
    this.riskRewardRatio,
    required this.commission,
    required this.swap,
    required this.requiredMargin,
    required this.freeMargin,
    required this.leverage,
    required this.contractSize,
    required this.tickSize,
    required this.tickValue,
    required this.volumeMin,
    required this.volumeMax,
    required this.volumeStep,
    required this.priceDigits,
    this.validationErrors = const [],
    this.warnings = const [],
  });
}
