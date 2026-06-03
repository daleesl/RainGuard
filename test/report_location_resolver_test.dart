import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/services/report_location_resolver.dart';

void main() {
  group('ReportLocationResolver.cleanLocationName', () {
    test('trims a valid location name', () {
      expect(
        ReportLocationResolver.cleanLocationName('  Lingga, Calamba  '),
        'Lingga, Calamba',
      );
    });

    test('removes empty and fallback location labels', () {
      expect(ReportLocationResolver.cleanLocationName(''), isNull);
      expect(
        ReportLocationResolver.cleanLocationName('Unknown Location'),
        isNull,
      );
      expect(
        ReportLocationResolver.cleanLocationName('Location Error'),
        isNull,
      );
    });
  });
}
