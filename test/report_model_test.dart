import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/report_model.dart';

void main() {
  group('Report.fromFirestore', () {
    test('keeps image_urls unique and preserves the first photo', () {
      final report = Report.fromFirestore({
        'latitude': 14.2,
        'longitude': 121.1,
        'report_type': 'rain',
        'risk_level': 'risk',
        'description': 'Rain near the creek',
        'image_url': 'https://example.com/first.jpg',
        'image_urls': [
          'https://example.com/second.jpg',
          'https://example.com/first.jpg',
        ],
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 21, 20, 30)),
      }, 'report-1');

      expect(report.type, ReportType.rain);
      expect(report.risk, RiskLevel.risk);
      expect(report.imageUrl, 'https://example.com/first.jpg');
      expect(report.allImageUrls, [
        'https://example.com/first.jpg',
        'https://example.com/second.jpg',
      ]);
    });

    test('prefers verified review status from legacy report_status', () {
      final report = Report.fromFirestore({
        'latitude': 14.2,
        'longitude': 121.1,
        'report_type': 'flood',
        'risk_level': 'flood',
        'report_status': 'verified',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 21, 20, 30)),
      }, 'report-2');

      expect(report.reviewStatus, 'verified');
      expect(report.isAdminVerified, isTrue);
    });

    test('classifies active recent and archived freshness', () {
      expect(
        _reportCreatedAt(
          DateTime.now().subtract(const Duration(hours: 2)),
        ).freshness,
        ReportFreshness.active,
      );
      expect(
        _reportCreatedAt(
          DateTime.now().subtract(const Duration(hours: 10)),
        ).freshness,
        ReportFreshness.recent,
      );
      expect(
        _reportCreatedAt(
          DateTime.now().subtract(const Duration(hours: 30)),
        ).freshness,
        ReportFreshness.archived,
      );
    });
  });
}

Report _reportCreatedAt(DateTime createdAt) {
  return Report.fromFirestore({
    'latitude': 14.2,
    'longitude': 121.1,
    'report_type': 'rain',
    'risk_level': 'risk',
    'created_at': Timestamp.fromDate(createdAt),
  }, 'freshness-report');
}
