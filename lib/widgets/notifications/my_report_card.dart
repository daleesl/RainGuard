import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';
import 'notification_shared.dart';

class MyReportCard extends StatelessWidget {
  const MyReportCard({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reportName = MapHelper.getReportTypeName(report.type);
    final status = _statusInfo(report);

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
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MyReportThumbnail(report: report),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
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
                              const SizedBox(width: 8),
                              NotificationSeverityChip(
                                color: status.color,
                                label: status.label,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ReportMetaLine(
                            icon: Icons.place_rounded,
                            label: _locationLabel(report),
                          ),
                          const SizedBox(height: 5),
                          _ReportMetaLine(
                            icon: Icons.access_time_rounded,
                            label: timeago.format(report.createdAt),
                          ),
                          const SizedBox(height: 5),
                          _ReportMetaLine(
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
                                : '$reportName conditions were submitted.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1.4,
                              color: RainGuardColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _ReportProgressTracker(status: status.progressStatus),
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

  _MyReportStatusInfo _statusInfo(Report report) {
    if (report.isResolved) {
      return _MyReportStatusInfo(
        label: 'Resolved',
        color: Colors.green.shade700,
        progressStatus: _ReportProgressStatus.resolved,
      );
    }
    if (report.isRejected) {
      return _MyReportStatusInfo(
        label: 'Closed',
        color: Colors.blueGrey.shade600,
        progressStatus: _ReportProgressStatus.closed,
      );
    }
    if (report.isAdminVerified) {
      return _MyReportStatusInfo(
        label: 'Verified',
        color: Colors.green.shade700,
        progressStatus: _ReportProgressStatus.verified,
      );
    }
    return _MyReportStatusInfo(
      label: 'Pending review',
      color: Colors.amber.shade800,
      progressStatus: _ReportProgressStatus.pending,
    );
  }
}

class _MyReportThumbnail extends StatelessWidget {
  const _MyReportThumbnail({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final imageUrls = report.allImageUrls;
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 82,
        height: 86,
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

class _ReportMetaLine extends StatelessWidget {
  const _ReportMetaLine({required this.icon, required this.label});

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

class _ReportProgressTracker extends StatelessWidget {
  const _ReportProgressTracker({required this.status});

  final _ReportProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final adminActive = status != _ReportProgressStatus.pending;
    final finalActive =
        status == _ReportProgressStatus.resolved ||
        status == _ReportProgressStatus.closed;
    final finalColor = status == _ReportProgressStatus.closed
        ? Colors.blueGrey.shade600
        : Colors.green.shade700;

    return Row(
      children: [
        _ProgressStep(
          icon: Icons.description_outlined,
          isActive: true,
          label: 'Submitted',
          color: RainGuardColors.primary,
        ),
        const Expanded(child: _DottedProgressLine(isActive: true)),
        _ProgressStep(
          icon: Icons.manage_accounts_outlined,
          isActive: adminActive,
          label: 'Admin review',
          color: RainGuardColors.primary,
        ),
        Expanded(child: _DottedProgressLine(isActive: adminActive)),
        _ProgressStep(
          icon: Icons.check_rounded,
          isActive: finalActive,
          label: 'Published/Resolved',
          color: finalActive ? finalColor : Colors.blueGrey.shade300,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.isActive,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final bool isActive;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.blueGrey.shade300;
    final effectiveColor = isActive ? color : inactiveColor;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? effectiveColor : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: effectiveColor, width: 2),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : effectiveColor,
              size: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? effectiveColor : RainGuardColors.secondaryText,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedProgressLine extends StatelessWidget {
  const _DottedProgressLine({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(
        color: isActive ? RainGuardColors.primary : Colors.blueGrey.shade300,
      ),
      child: const SizedBox(height: 32),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    const dashWidth = 3.5;
    const dashGap = 4.5;
    var startX = 0.0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

enum _ReportProgressStatus { pending, verified, resolved, closed }

class _MyReportStatusInfo {
  const _MyReportStatusInfo({
    required this.label,
    required this.color,
    required this.progressStatus,
  });

  final String label;
  final Color color;
  final _ReportProgressStatus progressStatus;
}
