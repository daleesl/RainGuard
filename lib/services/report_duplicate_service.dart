import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report_model.dart';

class ReportDuplicateService {
  const ReportDuplicateService._();

  static const Duration duplicateWindow = Duration(minutes: 15);
  static const double duplicateRadiusMeters = 250;

  static Future<Report?> findRecentDuplicateReport({
    required ReportType type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(duplicateWindow),
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('created_at', isGreaterThan: cutoff)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final report = Report.fromFirestore(doc.data(), doc.id);
        if (report.type != type) continue;

        final distance = _distanceMeters(
          latitude,
          longitude,
          report.latitude,
          report.longitude,
        );
        if (distance <= duplicateRadiusMeters) {
          return report;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  @visibleForTesting
  static double testDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return _distanceMeters(lat1, lng1, lat2, lng2);
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
