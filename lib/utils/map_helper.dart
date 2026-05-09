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

  static IconData getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.rain:
        return Icons.umbrella;
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
}
