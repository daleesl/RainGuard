import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/services/notification_preference_service.dart';

void main() {
  group('NotificationPreference', () {
    test('maps every option to the stored Firestore value', () {
      expect(
        NotificationPreference.allReports.firestoreValue,
        'all_reports',
      );
      expect(NotificationPreference.floodOnly.firestoreValue, 'flood_only');
      expect(NotificationPreference.nearbyOnly.firestoreValue, 'nearby_only');
      expect(
        NotificationPreference.highRiskOnly.firestoreValue,
        'high_risk_only',
      );
    });

    test('parses stored values and falls back to all reports', () {
      expect(
        NotificationPreference.fromFirestoreValue('flood_only'),
        NotificationPreference.floodOnly,
      );
      expect(
        NotificationPreference.fromFirestoreValue('nearby_only'),
        NotificationPreference.nearbyOnly,
      );
      expect(
        NotificationPreference.fromFirestoreValue('high_risk_only'),
        NotificationPreference.highRiskOnly,
      );
      expect(
        NotificationPreference.fromFirestoreValue('unknown'),
        NotificationPreference.allReports,
      );
      expect(
        NotificationPreference.fromFirestoreValue(null),
        NotificationPreference.allReports,
      );
    });

    test('keeps user-facing labels and descriptions available', () {
      for (final preference in NotificationPreference.values) {
        expect(preference.label, isNotEmpty);
        expect(preference.description, isNotEmpty);
      }
    });
  });
}
