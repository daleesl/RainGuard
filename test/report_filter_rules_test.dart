import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/report_model.dart';
import 'package:rainguard_app/utils/map_report_filter.dart';
import 'package:rainguard_app/utils/report_filter_rules.dart';

void main() {
  group('filterMapReports', () {
    final reports = [
      _report(id: 'rain-1', type: ReportType.rain),
      _report(id: 'flood-1', type: ReportType.flood),
      _report(
        id: 'verified-1',
        type: ReportType.flood,
        reviewStatus: 'verified',
      ),
    ];

    test('keeps every active-map report for the active filter', () {
      expect(filterMapReports(reports, MapReportFilter.active), reports);
    });

    test('filters rain reports', () {
      final filtered = filterMapReports(reports, MapReportFilter.rain);

      expect(filtered.map((report) => report.id), ['rain-1']);
    });

    test('filters flood reports', () {
      final filtered = filterMapReports(reports, MapReportFilter.flood);

      expect(filtered.map((report) => report.id), ['flood-1', 'verified-1']);
    });

    test('filters admin verified reports', () {
      final filtered = filterMapReports(reports, MapReportFilter.verified);

      expect(filtered.map((report) => report.id), ['verified-1']);
    });

    test('returns an empty list when the filter has no matches', () {
      final filtered = filterMapReports(
        [_report(id: 'rain-only', type: ReportType.rain)],
        MapReportFilter.flood,
      );

      expect(filtered, isEmpty);
    });

    test('keeps report order after filtering', () {
      final orderedReports = [
        _report(id: 'flood-first', type: ReportType.flood),
        _report(id: 'rain-middle', type: ReportType.rain),
        _report(id: 'flood-last', type: ReportType.flood),
      ];

      final filtered = filterMapReports(orderedReports, MapReportFilter.flood);

      expect(filtered.map((report) => report.id), [
        'flood-first',
        'flood-last',
      ]);
    });
  });
}

Report _report({
  required String id,
  ReportType type = ReportType.rain,
  String reviewStatus = 'active',
}) {
  return Report(
    id: id,
    latitude: 14.2,
    longitude: 121.1,
    type: type,
    risk: type == ReportType.flood ? RiskLevel.flood : RiskLevel.risk,
    description: 'Test report',
    reviewStatus: reviewStatus,
    createdAt: DateTime.now(),
  );
}
