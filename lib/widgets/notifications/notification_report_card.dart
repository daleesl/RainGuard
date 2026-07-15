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
    final reportName = MapHelper.getReportTypeName(report.type);
    final color = report.isAdminVerified
        ? Colors.green.shade700
        : RainGuardColors.primary;
    final label = report.isAdminVerified ? 'Verified' : 'Community';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
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
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportThumbnail(report: report),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 92),
                              child: Text(
                                '$reportName Report',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: RainGuardColors.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _MetaLine(
                              icon: Icons.place_rounded,
                              label: _locationLabel(report),
                            ),
                            const SizedBox(height: 5),
                            _MetaLine(
                              icon: Icons.verified_user_outlined,
                              label: report.isAdminVerified
                                  ? 'Verified community report'
                                  : 'Reported by community resident',
                            ),
                            const SizedBox(height: 5),
                            _MetaLine(
                              icon: report.type == ReportType.flood
                                  ? Icons.water_drop_outlined
                                  : Icons.thunderstorm_outlined,
                              label:
                                  '${report.observationLabel}: ${report.observationValue}',
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report.description.isNotEmpty
                                  ? report.description
                                  : '$reportName conditions were reported nearby.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 8,
                                height: 1.4,
                                color: RainGuardColors.ink,
                              ),
                            ),
                            const SizedBox(height: 11),
                            NotificationMetaPill(
                              color: RainGuardColors.primary,
                              icon: Icons.access_time_rounded,
                              label: timeago.format(report.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: NotificationSeverityChip(color: color, label: label),
                ),
                const Positioned(
                  top: 42,
                  right: 0,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: RainGuardColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _locationLabel(Report report) {
    final location = report.locationName;
    if (location != null && location.isNotEmpty) return location;
    return 'Quiling, Talisay';
  }
}

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final imageUrls = report.allImageUrls;
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 82,
        height: 92,
        color: RainGuardColors.softBlue,
        child: imageUrl == null
            ? Icon(
                MapHelper.getReportIcon(report.type),
                color: RainGuardColors.primary,
                size: 30,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  MapHelper.getReportIcon(report.type),
                  color: RainGuardColors.primary,
                  size: 30,
                ),
              ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: RainGuardColors.primary, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
