import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/report_model.dart';
import '../theme/rainguard_theme.dart';
import '../utils/map_helper.dart';
import '../widgets/report_details_dialog.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/rainGuard-Logo.svg',
              width: 25,
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'RainGuard',
              style: RainGuardTextStyles.appBarTitle,
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }

          final docs = snapshot.data?.docs ?? [];
          final reports = <Report>[];

          for (final doc in docs) {
            try {
              reports.add(
                Report.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
              );
            } catch (e) {
              debugPrint('Error parsing notification report ${doc.id}: $e');
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: RainGuardColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap an alert to see images, description, risk level, and report time.',
                style: TextStyle(color: RainGuardColors.secondaryText, height: 1.35),
              ),
              const SizedBox(height: 18),
              if (reports.isEmpty)
                const _EmptyNotifications()
              else
                ...reports.map(
                  (report) => _NotificationCard(
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
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report);
    final bgColor = color.withOpacity(0.10);
    final reportName = MapHelper.getReportTypeName(report.type);
    final title = report.risk == RiskLevel.flood
        ? '$reportName Report Detected'
        : '$reportName Alert Detected';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        MapHelper.getReportIcon(report.type),
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: report.risk == RiskLevel.flood
                                  ? color
                                  : RainGuardColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reported by ${report.reporterName ?? 'Anonymous reporter'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RainGuardColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: RainGuardColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  report.description.isNotEmpty
                      ? report.description
                      : '$reportName was reported near your monitored area.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: RainGuardColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (report.floodLevel != null)
                      _MetaPill(
                        color: color,
                        icon: Icons.water_drop_outlined,
                        label: report.floodLevel!,
                      ),
                    _MetaPill(
                      color: Colors.blueGrey,
                      icon: Icons.access_time_rounded,
                      label: timeago.format(report.createdAt),
                    ),
                    _MetaPill(
                      color: color,
                      icon: Icons.warning_amber_rounded,
                      label: MapHelper.getRiskLevelName(report.risk),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(Report report) {
    if (report.risk == RiskLevel.flood) return Colors.red.shade700;
    if (report.risk == RiskLevel.risk || report.type == ReportType.rain) {
      return Colors.amber.shade800;
    }
    return Colors.green.shade700;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 44,
            color: RainGuardColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: RainGuardColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'RainGuard will show community reports and weather alerts here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RainGuardColors.secondaryText, height: 1.4),
          ),
        ],
      ),
    );
  }
}
