import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_feed.dart';
import '../models/report_model.dart';
import '../models/safety_alert.dart';
import 'alert_service.dart';

class NotificationFeedService {
  const NotificationFeedService._();

  static const int defaultReportLimit = 75;

  static Stream<NotificationFeed> feedStream({
    int alertLimit = AlertService.defaultAlertLimit,
    int reportLimit = defaultReportLimit,
  }) {
    final controller = StreamController<NotificationFeed>();
    List<SafetyAlert>? latestAlerts;
    List<Report>? latestReports;
    StreamSubscription<List<SafetyAlert>>? alertsSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
        reportsSubscription;

    void emitFeedIfReady() {
      final alerts = latestAlerts;
      final reports = latestReports;
      if (alerts == null || reports == null || controller.isClosed) return;

      controller.add(NotificationFeed(alerts: alerts, reports: reports));
    }

    controller.onListen = () {
      alertsSubscription = AlertService.publishedAlertsStream(
        limitCount: alertLimit,
      ).listen(
        (alerts) {
          latestAlerts = alerts;
          emitFeedIfReady();
        },
        onError: (error) {
          debugPrint('Error loading safety alerts: $error');
          latestAlerts = const <SafetyAlert>[];
          emitFeedIfReady();
        },
      );

      reportsSubscription = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('created_at', descending: true)
          .limit(reportLimit)
          .snapshots()
          .listen(
        (snapshot) {
          latestReports = _parseReports(snapshot.docs);
          emitFeedIfReady();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () async {
      await alertsSubscription?.cancel();
      await reportsSubscription?.cancel();
    };

    return controller.stream;
  }

  static List<Report> _parseReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final reports = <Report>[];

    for (final doc in docs) {
      try {
        reports.add(Report.fromFirestore(doc.data(), doc.id));
      } catch (error) {
        debugPrint('Error parsing notification report ${doc.id}: $error');
      }
    }

    return reports;
  }
}
