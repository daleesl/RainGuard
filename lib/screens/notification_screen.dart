import 'package:flutter/material.dart';

import '../models/notification_feed.dart';
import '../models/report_model.dart';
import '../services/notification_feed_service.dart';
import '../theme/rainguard_theme.dart';
import '../widgets/notifications/empty_notifications.dart';
import '../widgets/notifications/notification_filter_bar.dart';
import '../widgets/notifications/notification_report_card.dart';
import '../widgets/notifications/notification_shared.dart';
import '../widgets/notifications/notification_summary_card.dart';
import '../widgets/notifications/safety_alert_card.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/report_details_dialog.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  late final Stream<NotificationFeed> _feedStream =
      NotificationFeedService.feedStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<NotificationFeed>(
        stream: _feedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }

          final feed =
              snapshot.data ?? const NotificationFeed(alerts: [], reports: []);
          final alerts = feed.alerts;
          final reports = feed.reports;
          final filteredReports = _filterReports(reports);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: RainGuardColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Latest community reports and flood-safety updates for Calamba.',
                style: TextStyle(
                  color: RainGuardColors.secondaryText,
                  fontSize: 8,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              NotificationSummaryCard(
                totalReports: reports.length,
                activeRiskCount: feed.activeRiskCount,
                latestReport: feed.latestReport,
              ),
              const SizedBox(height: 18),
              NotificationFilterBar(
                selectedFilter: _selectedFilter,
                totalCount: reports.length,
                floodCount: reports
                    .where((report) => report.type == ReportType.flood)
                    .length,
                rainCount: reports
                    .where((report) => report.type == ReportType.rain)
                    .length,
                onChanged: (filter) {
                  if (filter == _selectedFilter) return;
                  setState(() => _selectedFilter = filter);
                },
              ),
              if (alerts.isNotEmpty) ...[
                const SizedBox(height: 18),
                const NotificationSectionHeader('Barangay Advisories'),
                const SizedBox(height: 10),
                ...alerts.map((alert) => SafetyAlertCard(alert: alert)),
              ],
              const SizedBox(height: 18),
              const NotificationSectionHeader('Recent Reports'),
              const SizedBox(height: 10),
              if (filteredReports.isEmpty && alerts.isEmpty)
                EmptyNotifications(filter: _selectedFilter)
              else
                ...filteredReports.map(
                  (report) => NotificationReportCard(
                    report: report,
                    onTap: () => ReportDetailsDialog.show(context, report),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Report> _filterReports(List<Report> reports) {
    switch (_selectedFilter) {
      case NotificationFilter.flood:
        return reports
            .where((report) => report.type == ReportType.flood)
            .toList();
      case NotificationFilter.rain:
        return reports
            .where((report) => report.type == ReportType.rain)
            .toList();
      case NotificationFilter.all:
        return reports;
    }
  }
}
