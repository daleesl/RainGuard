import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/safety_alert.dart';

class AlertService {
  const AlertService._();

  static const int defaultAlertLimit = 50;

  static Stream<List<SafetyAlert>> publishedAlertsStream({
    int limitCount = defaultAlertLimit,
  }) {
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'published')
        .orderBy('created_at', descending: true)
        .limit(limitCount)
        .snapshots()
        .map((snapshot) {
      final alerts = <SafetyAlert>[];

      for (final doc in snapshot.docs) {
        try {
          final alert = SafetyAlert.fromFirestore(doc.data(), doc.id);
          if (alert.isPublished) alerts.add(alert);
        } catch (error) {
          debugPrint('Error parsing safety alert ${doc.id}: $error');
        }
      }

      return alerts;
    });
  }
}
