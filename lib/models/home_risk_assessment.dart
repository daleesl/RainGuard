import 'report_model.dart';
import 'safety_alert.dart';

enum HomeFloodRiskLevel { clear, watch, high }

class HomeRiskAssessment {
  static const Duration _allowedFutureClockSkew = Duration(minutes: 5);

  const HomeRiskAssessment({
    required this.activeFloodReportCount,
    required this.activeOfficialAlertCount,
    required this.evaluatedAt,
    required this.lastSourceUpdateAt,
    required this.level,
    required this.reason,
  });

  factory HomeRiskAssessment.fromSources({
    required List<Report> reports,
    required List<SafetyAlert> alerts,
    required DateTime now,
    Duration reportWindow = const Duration(hours: 6),
    Duration officialAlertWindow = const Duration(hours: 24),
  }) {
    final activeFloodReports = reports.where((report) {
      return report.type == ReportType.flood &&
          !report.isResolved &&
          !report.isRejected &&
          _isWithinWindow(report.createdAt, now, reportWindow);
    }).toList();
    final activeOfficialAlerts = alerts.where((alert) {
      return alert.isPublished &&
          _isRiskAlert(alert.riskLevel) &&
          _isWithinWindow(alert.publishedAt, now, officialAlertWindow);
    }).toList();
    final highOfficialAlerts = activeOfficialAlerts
        .where((alert) => _isHighRiskAlert(alert.riskLevel))
        .toList();

    final HomeFloodRiskLevel level;
    if (activeFloodReports.isNotEmpty || highOfficialAlerts.isNotEmpty) {
      level = HomeFloodRiskLevel.high;
    } else if (activeOfficialAlerts.isNotEmpty) {
      level = HomeFloodRiskLevel.watch;
    } else {
      level = HomeFloodRiskLevel.clear;
    }

    return HomeRiskAssessment(
      activeFloodReportCount: activeFloodReports.length,
      activeOfficialAlertCount: activeOfficialAlerts.length,
      evaluatedAt: now,
      lastSourceUpdateAt: _latestUpdate(
        reports: activeFloodReports,
        alerts: activeOfficialAlerts,
      ),
      level: level,
      reason: _reasonFor(
        level: level,
        floodReportCount: activeFloodReports.length,
        officialAlertCount: activeOfficialAlerts.length,
      ),
    );
  }

  final int activeFloodReportCount;
  final int activeOfficialAlertCount;
  final DateTime evaluatedAt;
  final DateTime? lastSourceUpdateAt;
  final HomeFloodRiskLevel level;
  final String reason;

  bool get hasActiveRisk => level != HomeFloodRiskLevel.clear;

  DateTime get lastUpdatedAt => lastSourceUpdateAt ?? evaluatedAt;

  String get levelLabel {
    switch (level) {
      case HomeFloodRiskLevel.high:
        return 'High';
      case HomeFloodRiskLevel.watch:
        return 'Watch';
      case HomeFloodRiskLevel.clear:
        return 'Green';
    }
  }

  static bool _isWithinWindow(
    DateTime timestamp,
    DateTime now,
    Duration window,
  ) {
    if (timestamp.isAfter(now.add(_allowedFutureClockSkew))) return false;

    final age = now.difference(timestamp);
    return age.isNegative || age <= window;
  }

  static bool _isRiskAlert(String riskLevel) {
    final normalized = riskLevel.trim().toLowerCase();
    return normalized == 'watch' || _isHighRiskAlert(normalized);
  }

  static bool _isHighRiskAlert(String riskLevel) {
    final normalized = riskLevel.trim().toLowerCase();
    return normalized == 'critical' ||
        normalized == 'warning' ||
        normalized == 'flood' ||
        normalized == 'high' ||
        normalized == 'high_risk';
  }

  static DateTime? _latestUpdate({
    required List<Report> reports,
    required List<SafetyAlert> alerts,
  }) {
    DateTime? latest;

    for (final report in reports) {
      if (latest == null || report.createdAt.isAfter(latest)) {
        latest = report.createdAt;
      }
    }
    for (final alert in alerts) {
      if (latest == null || alert.publishedAt.isAfter(latest)) {
        latest = alert.publishedAt;
      }
    }

    return latest;
  }

  static String _reasonFor({
    required HomeFloodRiskLevel level,
    required int floodReportCount,
    required int officialAlertCount,
  }) {
    if (level == HomeFloodRiskLevel.clear) {
      return 'No active flood reports or official warnings';
    }

    final reportLabel =
        '$floodReportCount active flood report${floodReportCount == 1 ? '' : 's'}';
    final alertLabel =
        '$officialAlertCount official alert${officialAlertCount == 1 ? '' : 's'}';

    if (floodReportCount > 0 && officialAlertCount > 0) {
      return '$alertLabel and $reportLabel';
    }
    if (officialAlertCount > 0) {
      return level == HomeFloodRiskLevel.watch
          ? '$alertLabel under watch'
          : '$alertLabel warning residents';
    }
    return '$reportLabel in the last 6 hours';
  }
}
