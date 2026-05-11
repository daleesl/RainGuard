import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/report_model.dart';
import '../theme/rainguard_theme.dart';
import '../utils/map_helper.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_card.dart';
import '../widgets/report_details_dialog.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
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
                Report.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              );
            } catch (e) {
              debugPrint('Error parsing notification report ${doc.id}: $e');
            }
          }

          final activeRiskCount = reports
              .where(
                (report) =>
                    report.risk == RiskLevel.flood ||
                    report.risk == RiskLevel.risk,
              )
              .length;
          final latestReport = reports.isNotEmpty ? reports.first : null;

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
              _NotificationSummaryCard(
                totalReports: reports.length,
                activeRiskCount: activeRiskCount,
                latestReport: latestReport,
              ),
              const SizedBox(height: 18),
              const _SectionHeader('Recent Alerts'),
              const SizedBox(height: 10),
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
    final reportName = MapHelper.getReportTypeName(report.type);
    final title = report.risk == RiskLevel.flood
        ? '$reportName report needs attention'
        : '$reportName update near monitored area';
    final reporterName = report.reporterName ?? 'Anonymous reporter';
    final hasImage = report.imageUrl != null && report.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: RainGuardColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(22),
                      ),
                    ),
                  ),
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
                                  color: color.withOpacity(0.10),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
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
                                        color: RainGuardColors.secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _SeverityChip(
                                color: color,
                                label: MapHelper.getRiskLevelName(report.risk),
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
                              _MetaPill(
                                color: Colors.blueGrey,
                                icon: Icons.access_time_rounded,
                                label: timeago.format(report.createdAt),
                              ),
                              if (report.floodLevel != null)
                                _MetaPill(
                                  color: color,
                                  icon: Icons.water_drop_outlined,
                                  label: report.floodLevel!,
                                ),
                              if (hasImage)
                                _MetaPill(
                                  color: RainGuardColors.primary,
                                  icon: Icons.image_outlined,
                                  label: 'Photo attached',
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

class _NotificationSummaryCard extends StatelessWidget {
  const _NotificationSummaryCard({
    required this.totalReports,
    required this.activeRiskCount,
    required this.latestReport,
  });

  final int totalReports;
  final int activeRiskCount;
  final Report? latestReport;

  @override
  Widget build(BuildContext context) {
    final hasActiveRisk = activeRiskCount > 0;
    final statusColor = hasActiveRisk
        ? Colors.red.shade700
        : Colors.green.shade700;
    final latestText = latestReport == null
        ? 'No reports yet'
        : '${MapHelper.getReportTypeName(latestReport!.type)} ${timeago.format(latestReport!.createdAt)}';

    return RainGuardCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      shadowOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  hasActiveRisk
                      ? Icons.notification_important_outlined
                      : Icons.shield_outlined,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActiveRisk
                          ? 'Active alerts in your area'
                          : 'No active flood alerts',
                      style: const TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      latestText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Reports',
                  value: '$totalReports',
                  color: RainGuardColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Need attention',
                  value: '$activeRiskCount',
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: RainGuardColors.sectionLabel,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
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
        color: color.withOpacity(0.08),
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
              fontSize: 8,
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
              fontSize: 12,
              color: RainGuardColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'RainGuard will show community reports and weather alerts here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
