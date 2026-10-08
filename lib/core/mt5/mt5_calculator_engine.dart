import 'mt5_models.dart';
import 'dart:math';

class MT5RiskEngine {
  /// Main entry point to calculate trade size and risk
  static TradeCalculationResult calculate(TradeCalculationRequest request) {
    List<String> errors = [];
    List<String> warnings = [];

    // 1. Basic Validation
    if (request.entryPrice <= 0) errors.add("Entry Price must be > 0.");
    if (request.stopLoss <= 0) errors.add("Stop Loss must be > 0.");
    if (request.takeProfit != null && request.takeProfit! <= 0) {
      errors.add("Take Profit must be > 0.");
    }
    if (request.riskPercentage <= 0) errors.add("Risk must be > 0.");
    if (request.accountBalance <= 0) errors.add("Balance must be > 0.");
    if (request.accountEquity <= 0) errors.add("Equity must be > 0.");
    if (request.symbolSpec.tickSize <= 0) errors.add("Missing tick size.");
    if (request.symbolSpec.tickValueLoss <= 0) errors.add("Missing tick value.");

    // Direction Validation
    if (request.direction == MT5TradeDirection.buy) {
      if (request.stopLoss >= request.entryPrice) {
        errors.add("Invalid BUY price structure: Stop Loss must be below Entry Price.");
      }
      if (request.takeProfit != null && request.takeProfit! <= request.entryPrice) {
        errors.add("Invalid BUY price structure: Take Profit must be above Entry Price.");
      }
    } else {
      if (request.stopLoss <= request.entryPrice) {
        errors.add("Invalid SELL price structure: Stop Loss must be above Entry Price.");
      }
      if (request.takeProfit != null && request.takeProfit! >= request.entryPrice) {
        errors.add("Invalid SELL price structure: Take Profit must be below Entry Price.");
      }
    }

    // Stops level validation
    double slDistanceInPoints = (request.entryPrice - request.stopLoss).abs() / request.symbolSpec.point;
    if (slDistanceInPoints < request.symbolSpec.stopsLevel) {
      errors.add("Stop Loss is too close to the entry price for this symbol/broker.");
    }

    if (request.takeProfit != null) {
      double tpDistanceInPoints = (request.takeProfit! - request.entryPrice).abs() / request.symbolSpec.point;
      if (tpDistanceInPoints < request.symbolSpec.stopsLevel) {
        errors.add("Take Profit is too close to the entry price for this symbol/broker.");
      }
    }

    if (errors.isNotEmpty) {
      return _createErrorResult(request, errors, warnings);
    }

    // 2. Risk Calculation
    double riskBaseAmount = request.riskBase == MT5RiskBase.balance 
        ? request.accountBalance 
        : request.accountEquity;
        
    double targetRiskAmount = riskBaseAmount * (request.riskPercentage / 100);

    // 3. Lot Calculation
    double priceDistance = (request.entryPrice - request.stopLoss).abs();
    double numberOfTicks = priceDistance / request.symbolSpec.tickSize;
    double lossPer1Lot = numberOfTicks * request.symbolSpec.tickValueLoss;

    double rawLotSize = targetRiskAmount / lossPer1Lot;

    // 4. Volume Normalization
    double finalLotSize = _normalizeVolume(rawLotSize, request.symbolSpec);

    if (finalLotSize < request.symbolSpec.volumeMin) {
      errors.add("No valid position size for selected risk (Minimum lot exceeds selected risk).");
      return _createErrorResult(request, errors, warnings);
    }
    
    if (finalLotSize > request.symbolSpec.volumeMax) {
      warnings.add("Maximum lot exceeded. Setting to max allowed.");
      finalLotSize = request.symbolSpec.volumeMax;
    }

    // 5. Actual Risk Recalculation
    double actualRiskAmount = finalLotSize * lossPer1Lot;

    // 6. Profit Calculation
    double? potentialProfit;
    double? riskRewardRatio;
    
    if (request.takeProfit != null) {
      double tpDistance = (request.takeProfit! - request.entryPrice).abs();
      double tpTicks = tpDistance / request.symbolSpec.tickSize;
      potentialProfit = tpTicks * request.symbolSpec.tickValueProfit * finalLotSize;
      
      if (priceDistance > 0) {
        riskRewardRatio = tpDistance / priceDistance;
      }
    }

    // 7. Commission and Swap
    double commissionAmount = _calculateCommission(request.commission, finalLotSize);
    double swapAmount = _calculateSwap(request.swap, request.direction, finalLotSize);

    // 8. Margin Calculation
    double requiredMargin = _calculateMargin(request, finalLotSize);
    double freeMargin = request.accountEquity - requiredMargin;

    if (requiredMargin > request.accountEquity) {
      errors.add("Insufficient free margin.");
    }

    return TradeCalculationResult(
      symbol: request.symbol,
      direction: request.direction,
      entryPrice: request.entryPrice,
      stopLoss: request.stopLoss,
      takeProfit: request.takeProfit,
      riskBase: request.riskBase,
      riskPercentage: request.riskPercentage,
      targetRiskAmount: targetRiskAmount,
      rawLotSize: rawLotSize,
      finalLotSize: finalLotSize,
      actualRiskAmount: actualRiskAmount,
      potentialProfit: potentialProfit,
      potentialLoss: actualRiskAmount,
      riskRewardRatio: riskRewardRatio,
      commission: commissionAmount,
      swap: swapAmount,
      requiredMargin: requiredMargin,
      freeMargin: freeMargin,
      leverage: request.leverage,
      contractSize: request.symbolSpec.contractSize,
      tickSize: request.symbolSpec.tickSize,
      tickValue: request.symbolSpec.tickValueLoss,
      volumeMin: request.symbolSpec.volumeMin,
      volumeMax: request.symbolSpec.volumeMax,
      volumeStep: request.symbolSpec.volumeStep,
      priceDigits: request.symbolSpec.digits,
      validationErrors: errors,
      warnings: warnings,
    );
  }

  static double _normalizeVolume(double rawLot, MT5SymbolSpecification spec) {
    if (rawLot < spec.volumeMin) return rawLot; // Will be caught by error check
    
    // Round down based on step size to avoid exceeding risk
    double steps = (rawLot / spec.volumeStep).floorToDouble();
    double normalized = steps * spec.volumeStep;
    
    // Fix floating point precision issues (e.g., 0.130000000001)
    int precision = _getDecimalPlaces(spec.volumeStep);
    return double.parse(normalized.toStringAsFixed(precision));
  }
  
  static int _getDecimalPlaces(double value) {
    String str = value.toString();
    int dotIndex = str.indexOf('.');
    if (dotIndex < 0) return 0;
    return str.length - dotIndex - 1;
  }

  static double _calculateCommission(CommissionModel? commission, double lotSize) {
    if (commission == null) return 0.0;
    switch (commission.type) {
      case CommissionType.perLot:
        return commission.value * lotSize;
      case CommissionType.perSide:
        return commission.value * lotSize * 2; // Assuming open and close
      case CommissionType.roundTurn:
        return commission.value * lotSize;
      case CommissionType.percentage:
        return 0.0; // Requires contract value, skipped for this basic implementation
    }
  }

  static double _calculateSwap(SwapModel? swap, MT5TradeDirection direction, double lotSize) {
    if (swap == null) return 0.0;
    return direction == MT5TradeDirection.buy 
        ? swap.longSwap * lotSize 
        : swap.shortSwap * lotSize;
  }

  static double _calculateMargin(TradeCalculationRequest request, double lotSize) {
    // Basic margin calculation based on mode
    double contractSize = request.symbolSpec.contractSize;
    
    switch (request.symbolSpec.calcMode) {
      case MT5CalcMode.forex:
      case MT5CalcMode.crypto:
        return (lotSize * contractSize * request.entryPrice) / request.leverage;
      case MT5CalcMode.cfd:
        return (lotSize * contractSize * request.entryPrice); // CFD margin often direct or uses specific percentage
      default:
        // Fallback standard calculation
        return (lotSize * contractSize * request.entryPrice) / request.leverage;
    }
  }

  static TradeCalculationResult _createErrorResult(
    TradeCalculationRequest request, 
    List<String> errors, 
    List<String> warnings
  ) {
    return TradeCalculationResult(
      symbol: request.symbol,
      direction: request.direction,
      entryPrice: request.entryPrice,
      stopLoss: request.stopLoss,
      takeProfit: request.takeProfit,
      riskBase: request.riskBase,
      riskPercentage: request.riskPercentage,
      targetRiskAmount: 0.0,
      rawLotSize: 0.0,
      finalLotSize: 0.0,
      actualRiskAmount: 0.0,
      potentialProfit: 0.0,
      potentialLoss: 0.0,
      riskRewardRatio: 0.0,
      commission: 0.0,
      swap: 0.0,
      requiredMargin: 0.0,
      freeMargin: request.accountEquity,
      leverage: request.leverage,
      contractSize: request.symbolSpec.contractSize,
      tickSize: request.symbolSpec.tickSize,
      tickValue: request.symbolSpec.tickValueLoss,
      volumeMin: request.symbolSpec.volumeMin,
      volumeMax: request.symbolSpec.volumeMax,
      volumeStep: request.symbolSpec.volumeStep,
      priceDigits: request.symbolSpec.digits,
      validationErrors: errors,
      warnings: warnings,
    );
  }
}
