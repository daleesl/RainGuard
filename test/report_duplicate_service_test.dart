import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/services/report_duplicate_service.dart';

void main() {
  group('ReportDuplicateService', () {
    test('calculates nearby report distance within duplicate radius', () {
      final distance = ReportDuplicateService.testDistanceMeters(
        14.2042,
        121.1571,
        14.2048,
        121.1578,
      );

      expect(distance, lessThan(ReportDuplicateService.duplicateRadiusMeters));
    });

    test('calculates far report distance outside duplicate radius', () {
      final distance = ReportDuplicateService.testDistanceMeters(
        14.2042,
        121.1571,
        14.2150,
        121.1700,
      );

      expect(
        distance,
        greaterThan(ReportDuplicateService.duplicateRadiusMeters),
      );
    });
  });
}
