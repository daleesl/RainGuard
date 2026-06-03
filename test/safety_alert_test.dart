import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/safety_alert.dart';

void main() {
  group('SafetyAlert.fromFirestore', () {
    test('parses published alert fields', () {
      final publishedAt = DateTime(2026, 5, 21, 20, 30);
      final alert = SafetyAlert.fromFirestore({
        'area': 'Lingga',
        'message': 'Avoid low-lying roads.',
        'published_at': Timestamp.fromDate(publishedAt),
        'risk_level': 'warning',
        'status': 'published',
        'title': 'Flood Watch',
      }, 'alert-1');

      expect(alert.id, 'alert-1');
      expect(alert.area, 'Lingga');
      expect(alert.riskLevel, 'warning');
      expect(alert.status, 'published');
      expect(alert.publishedAt, publishedAt);
      expect(alert.isPublished, isTrue);
    });

    test('uses safe fallbacks for missing fields', () {
      final createdAt = DateTime(2026, 5, 21, 9);
      final alert = SafetyAlert.fromFirestore({
        'created_at': Timestamp.fromDate(createdAt),
      }, 'alert-2');

      expect(alert.area, 'All residents');
      expect(alert.message, '');
      expect(alert.riskLevel, 'info');
      expect(alert.status, 'draft');
      expect(alert.title, 'RainGuard advisory');
      expect(alert.publishedAt, createdAt);
      expect(alert.isPublished, isFalse);
    });

    test('normalizes alert status for reliable comparisons', () {
      final alert = SafetyAlert.fromFirestore({
        'status': ' Published ',
      }, 'alert-3');

      expect(alert.status, 'published');
      expect(alert.isPublished, isTrue);
    });
  });
}
