import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_feed.dart';
import '../models/report_model.dart';
import '../models/safety_alert.dart';
import 'alert_service.dart';
import 'report_feed_service.dart';

class NotificationFeedService {
  const NotificationFeedService._();

  static const int defaultReportLimit =
      ReportFeedService.defaultNotificationReportLimit;

  static Stream<NotificationFeed> feedStream({
    int alertLimit = AlertService.defaultAlertLimit,
    int reportLimit = defaultReportLimit,
  }) {
    final controller = StreamController<NotificationFeed>();
    List<SafetyAlert>? latestAlerts;
    List<Report>? latestReports;
    StreamSubscription<List<SafetyAlert>>? alertsSubscription;
    StreamSubscription<List<Report>>? reportsSubscription;

    void emitFeedIfReady() {
      final alerts = latestAlerts;
      final reports = latestReports;
      if (alerts == null || reports == null || controller.isClosed) return;

      controller.add(NotificationFeed(alerts: alerts, reports: reports));
    }

    controller.onListen = () {
      alertsSubscription =
          AlertService.publishedAlertsStream(limitCount: alertLimit).listen(
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

      reportsSubscription =
          ReportFeedService.latestReportsStream(limitCount: reportLimit).listen(
            (reports) {
              latestReports = reports;
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
}
