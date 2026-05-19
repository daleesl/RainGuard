import 'package:flutter/material.dart';
import '../models/report_model.dart';

class MapHelper {
  static Color getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.safe:
        return Colors.green;
      case RiskLevel.risk:
        return Colors.yellowAccent.shade700;
      case RiskLevel.flood:
        return Colors.red;
    }
  }

  static Color getReportColor(Report report) {
    if (report.freshness == ReportFreshness.archived) {
      return Colors.blueGrey.shade400;
    }

    final riskColor = getRiskColor(report.risk);
    if (report.freshness == ReportFreshness.recent) {
      return Color.lerp(riskColor, Colors.blueGrey.shade400, 0.35) ??
          riskColor;
    }
    return riskColor;
  }

  static double getReportOpacity(Report report) {
    switch (report.freshness) {
      case ReportFreshness.active:
        return 1;
      case ReportFreshness.recent:
        return 0.72;
      case ReportFreshness.archived:
        return 0.48;
    }
  }

  static IconData getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.rain:
        return Icons.thunderstorm_outlined;
      case ReportType.flood:
        return Icons.waves;
    }
  }

  static String getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.rain:
        return "Rain";
      case ReportType.flood:
        return "Flood";
    }
  }

  static String getRiskLevelName(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.safe:
        return "Safe";
      case RiskLevel.risk:
        return "Risk";
      case RiskLevel.flood:
        return "Flood";
    }
  }

  static String getFreshnessName(ReportFreshness freshness) {
    switch (freshness) {
      case ReportFreshness.active:
        return "Active";
      case ReportFreshness.recent:
        return "Recent";
      case ReportFreshness.archived:
        return "Archived";
    }
  }

  static String getFreshnessDescription(ReportFreshness freshness) {
    switch (freshness) {
      case ReportFreshness.active:
        return "Reported within 6 hours";
      case ReportFreshness.recent:
        return "Reported within 24 hours";
      case ReportFreshness.archived:
        return "Older than 24 hours";
    }
  }
}
