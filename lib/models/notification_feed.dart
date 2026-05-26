import 'report_model.dart';
import 'safety_alert.dart';

class NotificationFeed {
  const NotificationFeed({
    required this.alerts,
    required this.reports,
  });

  final List<SafetyAlert> alerts;
  final List<Report> reports;

  int get activeRiskCount {
    final riskReports = reports.where(
      (report) =>
          !report.isArchived &&
          (report.risk == RiskLevel.flood || report.risk == RiskLevel.risk),
    );

    return riskReports.length + alerts.length;
  }

  Report? get latestReport => reports.isNotEmpty ? reports.first : null;
}
