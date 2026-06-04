import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/home_risk_assessment.dart';
import 'package:rainguard_app/models/report_model.dart';
import 'package:rainguard_app/models/safety_alert.dart';

void main() {
  final now = DateTime(2026, 6, 5, 12);

  test('ignores old and resolved flood reports', () {
    final assessment = HomeRiskAssessment.fromSources(
      reports: [
        _report(
          id: 'old',
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        _report(
          id: 'resolved',
          createdAt: now.subtract(const Duration(hours: 1)),
          reviewStatus: 'resolved',
        ),
        _report(
          id: 'rejected',
          createdAt: now.subtract(const Duration(hours: 1)),
          reviewStatus: 'rejected',
        ),
        _report(
          id: 'duplicate',
          createdAt: now.subtract(const Duration(hours: 1)),
          reviewStatus: 'duplicate_hidden',
        ),
      ],
      alerts: const [],
      now: now,
    );

    expect(assessment.level, HomeFloodRiskLevel.clear);
    expect(assessment.activeFloodReportCount, 0);
  });

  test('marks recent unresolved flood reports as high risk', () {
    final createdAt = now.subtract(const Duration(hours: 2));
    final assessment = HomeRiskAssessment.fromSources(
      reports: [_report(id: 'active', createdAt: createdAt)],
      alerts: const [],
      now: now,
    );

    expect(assessment.level, HomeFloodRiskLevel.high);
    expect(assessment.activeFloodReportCount, 1);
    expect(assessment.lastUpdatedAt, createdAt);
  });

  test('ignores reports with timestamps far in the future', () {
    final assessment = HomeRiskAssessment.fromSources(
      reports: [
        _report(id: 'future', createdAt: now.add(const Duration(days: 1))),
      ],
      alerts: const [],
      now: now,
    );

    expect(assessment.level, HomeFloodRiskLevel.clear);
    expect(assessment.activeFloodReportCount, 0);
  });

  test('uses official watch and warning severity', () {
    final watch = HomeRiskAssessment.fromSources(
      reports: const [],
      alerts: [_alert(riskLevel: 'watch', publishedAt: now)],
      now: now,
    );
    final warning = HomeRiskAssessment.fromSources(
      reports: const [],
      alerts: [_alert(riskLevel: 'warning', publishedAt: now)],
      now: now,
    );

    expect(watch.level, HomeFloodRiskLevel.watch);
    expect(warning.level, HomeFloodRiskLevel.high);
  });

  test('ignores expired and resolved official alerts', () {
    final assessment = HomeRiskAssessment.fromSources(
      reports: const [],
      alerts: [
        _alert(
          riskLevel: 'warning',
          publishedAt: now.subtract(const Duration(hours: 25)),
        ),
        _alert(riskLevel: 'warning', publishedAt: now, status: 'resolved'),
      ],
      now: now,
    );

    expect(assessment.level, HomeFloodRiskLevel.clear);
    expect(assessment.activeOfficialAlertCount, 0);
  });
}

Report _report({
  required String id,
  required DateTime createdAt,
  String reviewStatus = 'active',
}) {
  return Report(
    id: id,
    latitude: 14.2,
    longitude: 121.1,
    type: ReportType.flood,
    risk: RiskLevel.flood,
    description: 'Flood report',
    reviewStatus: reviewStatus,
    createdAt: createdAt,
  );
}

SafetyAlert _alert({
  required String riskLevel,
  required DateTime publishedAt,
  String status = 'published',
}) {
  return SafetyAlert(
    area: 'Lingga',
    id: riskLevel,
    message: 'Stay alert.',
    publishedAt: publishedAt,
    riskLevel: riskLevel,
    status: status,
    title: 'Flood advisory',
  );
}
