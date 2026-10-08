import 'package:flutter_test/flutter_test.dart';
import 'package:finance_27/core/jar_distribution_service.dart';
import 'package:finance_27/models/jar_model.dart';

void main() {
  group('JarDistributionService Tests', () {
    test('Should distribute income correctly according to percentages', () {
      const double income = 1000.0;
      final distribution = JarDistributionService.distribute(income);

      expect(distribution[JarType.necessities], 550.0);
      expect(distribution[JarType.financialFreedom], 100.0);
      expect(distribution[JarType.longTermSavings], 100.0);
      expect(distribution[JarType.education], 100.0);
      expect(distribution[JarType.play], 100.0);
      expect(distribution[JarType.giving], 50.0);
    });

    test('Should handle zero income', () {
      const double income = 0.0;
      final distribution = JarDistributionService.distribute(income);

      for (var amount in distribution.values) {
        expect(amount, 0.0);
      }
    });
  });
}
