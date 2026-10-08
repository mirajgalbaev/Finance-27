import 'package:finance_27/models/jar_model.dart';

class JarDistributionService {
  static Map<JarType, double> distribute(double amount) {
    return {
      for (var type in JarType.values)
        type: amount * type.percentage,
    };
  }
}
