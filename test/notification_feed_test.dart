import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/notification_feed.dart';
import 'package:rainguard_app/models/report_model.dart';
import 'package:rainguard_app/models/safety_alert.dart';

void main() {
  group('NotificationFeed', () {
    test('counts active risky reports and official alerts', () {
      final feed = NotificationFeed(
        alerts: [_alert(id: 'alert-1')],
        reports: [
          _report(
            id: 'active-risk',
            risk: RiskLevel.risk,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          _report(
            id: 'active-flood',
            risk: RiskLevel.flood,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          _report(
            id: 'safe-report',
            risk: RiskLevel.safe,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          _report(
            id: 'archived-risk',
            risk: RiskLevel.risk,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      );

      expect(feed.activeRiskCount, 3);
    });

    test('exposes the newest report as the latest report', () {
      final newest = _report(id: 'newest');
      final older = _report(id: 'older');

      expect(
        NotificationFeed(alerts: const [], reports: [newest, older])
            .latestReport,
        newest,
      );
      expect(
        const NotificationFeed(alerts: [], reports: []).latestReport,
        isNull,
      );
    });
  });
}

Report _report({
  required String id,
  RiskLevel risk = RiskLevel.risk,
  DateTime? createdAt,
}) {
  return Report(
    id: id,
    latitude: 14.2,
    longitude: 121.1,
    type: risk == RiskLevel.flood ? ReportType.flood : ReportType.rain,
    risk: risk,
    description: 'Notification report',
    createdAt: createdAt ?? DateTime.now(),
  );
}

SafetyAlert _alert({required String id}) {
  return SafetyAlert(
    area: 'Lingga',
    id: id,
    message: 'Stay alert.',
    publishedAt: DateTime.now(),
    riskLevel: 'warning',
    status: 'published',
    title: 'Flood warning',
  );
}
