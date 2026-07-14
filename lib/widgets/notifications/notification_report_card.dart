import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';
import 'notification_shared.dart';

class NotificationReportCard extends StatelessWidget {
  const NotificationReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report);
    final freshnessColor = MapHelper.getReportColor(report);
    final freshnessLabel = MapHelper.getFreshnessName(report.freshness);
    final reportName = MapHelper.getReportTypeName(report.type);
    final reporterName = report.reporterName ?? 'Anonymous reporter';
    final imageCount = report.allImageUrls.length;
    final hasImage = imageCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: report.isArchived
                  ? Colors.blueGrey.shade50
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: RainGuardColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    MapHelper.getReportIcon(report.type),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _title(report, reportName),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: RainGuardColors.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Reported by $reporterName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color:
                                              RainGuardColors.secondaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                NotificationSeverityChip(
                                  color: color,
                                  label: MapHelper.getRiskLevelName(
                                    report.risk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            Text(
                              report.description.isNotEmpty
                                  ? report.description
                                  : '$reportName was reported near your monitored area.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 8,
                                height: 1.4,
                                color: RainGuardColors.ink,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                NotificationMetaPill(
                                  color: freshnessColor,
                                  icon: Icons.access_time_rounded,
                                  label:
                                      '${timeago.format(report.createdAt)} - $freshnessLabel',
                                ),
                                if (report.floodLevel != null)
                                  NotificationMetaPill(
                                    color: color,
                                    icon: Icons.water_drop_outlined,
                                    label: report.floodLevel!,
                                  ),
                                if (hasImage)
                                  NotificationMetaPill(
                                    color: RainGuardColors.primary,
                                    icon: Icons.image_outlined,
                                    label: imageCount > 1
                                        ? '$imageCount photos'
                                        : 'Photo attached',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: RainGuardColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(Report report, String reportName) {
    if (report.isArchived) return 'Archived $reportName report';
    if (report.risk == RiskLevel.flood) {
      return '$reportName report needs attention';
    }
    return '$reportName update near monitored area';
  }

  Color _statusColor(Report report) {
    if (report.isArchived) return Colors.blueGrey.shade500;
    if (report.risk == RiskLevel.flood) return Colors.red.shade700;
    if (report.risk == RiskLevel.risk || report.type == ReportType.rain) {
      return Colors.amber.shade800;
    }
    return Colors.green.shade700;
  }
}
