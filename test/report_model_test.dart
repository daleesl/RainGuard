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

    test('treats flood submissions as flood risk when old data says risk', () {
      final report = Report.fromFirestore({
        'latitude': 14.2,
        'longitude': 121.1,
        'report_type': 'flood',
        'risk_level': 'risk',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 21, 20, 30)),
      }, 'legacy-flood-risk');

      expect(report.type, ReportType.flood);
      expect(report.risk, RiskLevel.flood);
      expect(report.isActiveOnMap, isTrue);
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

    test('keeps older unresolved reports on the map in a muted state', () {
      final report = Report.fromFirestore({
        'latitude': 14.2,
        'longitude': 121.1,
        'report_type': 'flood',
        'risk_level': 'flood',
        'status': 'active',
        'created_at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 80)),
        ),
      }, 'older-active-report');

      expect(report.isActiveOnMap, isTrue);
      expect(report.isMutedOnMap, isTrue);
    });

    test('does not mute recent unresolved map reports', () {
      final report = Report.fromFirestore({
        'latitude': 14.2,
        'longitude': 121.1,
        'report_type': 'flood',
        'risk_level': 'flood',
        'status': 'active',
        'created_at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 24)),
        ),
      }, 'recent-active-report');

      expect(report.isActiveOnMap, isTrue);
      expect(report.isMutedOnMap, isFalse);
    });

    test(
      'parses manual location metadata and hides resolved reports from map',
      () {
        final report = Report.fromFirestore({
          'latitude': 14.2,
          'longitude': 121.1,
          'report_type': 'flood',
          'risk_level': 'flood',
          'location_name': '  Lingga, Calamba  ',
          'location_source': 'manual',
          'status': 'resolved',
          'created_at': Timestamp.fromDate(DateTime(2026, 5, 21, 20, 30)),
        }, 'manual-report');

        expect(report.isManualLocation, isTrue);
        expect(report.locationSourceLabel, 'Manually selected');
        expect(report.locationName, 'Lingga, Calamba');
        expect(report.isResolved, isTrue);
        expect(report.isActiveOnMap, isFalse);
      },
    );

    test('hides rejected and hidden reports from the public map', () {
      for (final status in ['rejected', 'duplicate_hidden', 'hidden']) {
        final report = Report.fromFirestore({
          'latitude': 14.2,
          'longitude': 121.1,
          'report_type': 'flood',
          'risk_level': 'flood',
          'status': status,
          'created_at': Timestamp.fromDate(DateTime.now()),
        }, '$status-report');

        expect(report.isRejected, isTrue);
        expect(report.isActiveOnMap, isFalse);
      }
    });

    test('writes stable Firestore submission fields', () {
      final createdAt = DateTime(2026, 5, 21, 20, 30);
      final report = Report(
        id: 'report-3',
        latitude: 14.2042,
        longitude: 121.1571,
        type: ReportType.flood,
        risk: RiskLevel.risk,
        description: 'Flood near the chapel',
        imageUrls: const ['https://example.com/first.jpg'],
        floodLevel: 'ankle_deep',
        userId: 'user-1',
        reporterName: 'Juan D.',
        reporterDisplayName: 'Juan Dela Cruz',
        locationName: 'Lingga, Calamba',
        locationSource: 'manual',
        createdAt: createdAt,
      );

      final data = report.toFirestore();

      expect(data['user_id'], 'user-1');
      expect(data['reporter_name'], 'Juan D.');
      expect(data['reporter_display_name'], 'Juan Dela Cruz');
      expect(data['latitude'], 14.2042);
      expect(data['longitude'], 121.1571);
      expect(data['location_name'], 'Lingga, Calamba');
      expect(data['location_source'], 'manual');
      expect(data['report_type'], 'flood');
      expect(data['risk_level'], 'flood');
      expect(data['description'], 'Flood near the chapel');
      expect(data['image_url'], 'https://example.com/first.jpg');
      expect(data['image_urls'], ['https://example.com/first.jpg']);
      expect(data['flood_level'], 'ankle_deep');
      expect(data['rain_intensity'], isNull);
      expect(data['status'], 'active');
      expect((data['created_at'] as Timestamp).toDate(), createdAt);
    });

    test('writes rain intensity for rain submissions', () {
      final data = Report(
        id: 'rain-report',
        latitude: 14.2042,
        longitude: 121.1571,
        type: ReportType.rain,
        risk: RiskLevel.risk,
        description: 'Heavy rain',
        rainIntensity: 'Heavy rain',
        createdAt: DateTime(2026, 5, 21, 20, 30),
      ).toFirestore();

      expect(data['report_type'], 'rain');
      expect(data['rain_intensity'], 'Heavy rain');
      expect(data['flood_level'], isNull);
    });

    test('does not keep a flood level for rain submissions', () {
      final data = Report(
        id: 'rain-report',
        latitude: 14.2042,
        longitude: 121.1571,
        type: ReportType.rain,
        risk: RiskLevel.risk,
        description: 'Heavy rain',
        floodLevel: 'ankle_deep',
        rainIntensity: 'Moderate rain',
        createdAt: DateTime(2026, 5, 21, 20, 30),
      ).toFirestore();

      expect(data['report_type'], 'rain');
      expect(data['flood_level'], isNull);
      expect(data['rain_intensity'], 'Moderate rain');
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
