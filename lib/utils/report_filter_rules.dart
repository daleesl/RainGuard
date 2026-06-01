import '../models/report_model.dart';
import 'map_report_filter.dart';

List<Report> filterMapReports(List<Report> reports, MapReportFilter filter) {
  switch (filter) {
    case MapReportFilter.rain:
      return reports.where((report) => report.type == ReportType.rain).toList();
    case MapReportFilter.flood:
      return reports
          .where((report) => report.type == ReportType.flood)
          .toList();
    case MapReportFilter.verified:
      return reports.where((report) => report.isAdminVerified).toList();
    case MapReportFilter.active:
      return reports;
  }
}
