import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/home_risk_assessment.dart';
import '../models/safety_alert.dart';
import 'report_feed_service.dart';

class HomeRiskService {
  const HomeRiskService._();

  static const Duration activeReportWindow = Duration(hours: 6);
  static const Duration activeOfficialAlertWindow = Duration(hours: 24);

  static Future<HomeRiskAssessment> loadCurrentAssessment() async {
    final now = DateTime.now();
    final reportCutoff = Timestamp.fromDate(now.subtract(activeReportWindow));
    final alertCutoff = Timestamp.fromDate(
      now.subtract(activeOfficialAlertWindow),
    );
    final firestore = FirebaseFirestore.instance;

    final snapshots = await Future.wait([
      firestore
          .collection('reports')
          .where('report_type', isEqualTo: 'flood')
          .where('created_at', isGreaterThanOrEqualTo: reportCutoff)
          .orderBy('created_at', descending: true)
          .get(),
      firestore
          .collection('alerts')
          .where('status', isEqualTo: 'published')
          .where('published_at', isGreaterThanOrEqualTo: alertCutoff)
          .orderBy('published_at', descending: true)
          .get(),
    ]);

    final reports = ReportFeedService.parseReports(snapshots[0].docs);
    final alerts = _parseAlerts(snapshots[1].docs);

    return HomeRiskAssessment.fromSources(
      reports: reports,
      alerts: alerts,
      now: now,
      reportWindow: activeReportWindow,
      officialAlertWindow: activeOfficialAlertWindow,
    );
  }

  static List<SafetyAlert> _parseAlerts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final alerts = <SafetyAlert>[];

    for (final doc in docs) {
      try {
        alerts.add(SafetyAlert.fromFirestore(doc.data(), doc.id));
      } catch (error) {
        debugPrint('Error parsing Home safety alert ${doc.id}: $error');
      }
    }

    return alerts;
  }
}
