import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'location_service.dart';

enum NotificationPreference {
  allReports,
  floodOnly,
  nearbyOnly,
  highRiskOnly;

  String get firestoreValue {
    switch (this) {
      case NotificationPreference.allReports:
        return 'all_reports';
      case NotificationPreference.floodOnly:
        return 'flood_only';
      case NotificationPreference.nearbyOnly:
        return 'nearby_only';
      case NotificationPreference.highRiskOnly:
        return 'high_risk_only';
    }
  }

  String get label {
    switch (this) {
      case NotificationPreference.allReports:
        return 'All reports';
      case NotificationPreference.floodOnly:
        return 'Flood only';
      case NotificationPreference.nearbyOnly:
        return 'Nearby only';
      case NotificationPreference.highRiskOnly:
        return 'High-risk only';
    }
  }

  String get description {
    switch (this) {
      case NotificationPreference.allReports:
        return 'Notify me for every community report.';
      case NotificationPreference.floodOnly:
        return 'Only alert me when flood reports are submitted.';
      case NotificationPreference.nearbyOnly:
        return 'Only alert me for reports near my saved location.';
      case NotificationPreference.highRiskOnly:
        return 'Only alert me when reports need faster attention.';
    }
  }

  static NotificationPreference fromFirestoreValue(String? value) {
    return NotificationPreference.values.firstWhere(
      (preference) => preference.firestoreValue == value,
      orElse: () => NotificationPreference.allReports,
    );
  }
}

class NotificationPreferenceService {
  const NotificationPreferenceService._();

  static const double nearbyRadiusKm = 5;

  static Future<NotificationPreference> getCurrentPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return NotificationPreference.allReports;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return NotificationPreference.fromFirestoreValue(
      snapshot.data()?['notification_preference'] as String?,
    );
  }

  static Future<void> saveCurrentPreference(
    NotificationPreference preference,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Log in first to update notification preferences.');
    }

    final update = <String, dynamic>{
      'notification_preference': preference.firestoreValue,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (preference == NotificationPreference.nearbyOnly) {
      final position = await LocationService.getCurrentPosition();
      update.addAll({
        'notification_latitude': position.latitude,
        'notification_longitude': position.longitude,
        'notification_radius_km': nearbyRadiusKm,
      });
    } else {
      update.addAll({
        'notification_latitude': FieldValue.delete(),
        'notification_longitude': FieldValue.delete(),
        'notification_radius_km': FieldValue.delete(),
      });
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(update, SetOptions(merge: true));
  }
}
