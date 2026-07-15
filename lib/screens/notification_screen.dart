import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notification_feed.dart';
import '../models/report_model.dart';
import '../models/safety_alert.dart';
import '../services/notification_feed_service.dart';
import '../services/report_feed_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/firebase_error_messages.dart';
import '../widgets/notifications/empty_notifications.dart';
import '../widgets/notifications/my_report_card.dart';
import '../widgets/notifications/notification_filter_bar.dart';
import '../widgets/notifications/notification_report_card.dart';
import '../widgets/notifications/notification_shared.dart';
import '../widgets/notifications/safety_alert_card.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_state_message.dart';
import '../widgets/report_details_dialog.dart';

enum _NotificationTab { community, myReports }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  _NotificationTab _selectedTab = _NotificationTab.community;
  NotificationFilter _communityFilter = NotificationFilter.all;
  NotificationFilter _myReportsFilter = NotificationFilter.all;
  late final Stream<NotificationFeed> _feedStream =
      NotificationFeedService.feedStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<NotificationFeed>(
        stream: _feedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: RainGuardStateMessage(
                icon: Icons.notifications_active_outlined,
                title: 'Loading notifications',
                message: 'Checking the latest reports and barangay advisories.',
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RainGuardStateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Notifications unavailable',
                  message: friendlyFirebaseError(
                    snapshot.error,
                    fallback: 'Error loading notifications.',
                  ),
                  iconColor: Colors.red.shade700,
                ),
              ),
            );
          }

          final feed =
              snapshot.data ?? const NotificationFeed(alerts: [], reports: []);
          final alerts = _sortAlerts(feed.alerts);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final communityReports = _communityReports(
            feed.reports,
            currentUserId,
          );

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
              Text(
                _selectedTab == _NotificationTab.myReports
                    ? 'Track your submitted reports.'
                    : 'Official advisories and community updates.',
                style: const TextStyle(
                  color: RainGuardColors.secondaryText,
                  fontSize: 8,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _NotificationTabSelector(
                selectedTab: _selectedTab,
                onChanged: (tab) {
                  if (tab == _selectedTab) return;
                  setState(() => _selectedTab = tab);
                },
              ),
              const SizedBox(height: 14),
              if (_selectedTab == _NotificationTab.community)
                _CommunityUpdatesView(
                  alerts: alerts,
                  reports: communityReports,
                  selectedFilter: _communityFilter,
                  onFilterChanged: (filter) {
                    if (filter == _communityFilter) return;
                    setState(() => _communityFilter = filter);
                  },
                  onReportTap: (report) =>
                      ReportDetailsDialog.show(context, report),
                )
              else
                _MyReportsStreamView(
                  currentUserId: currentUserId,
                  selectedFilter: _myReportsFilter,
                  onFilterChanged: (filter) {
                    if (filter == _myReportsFilter) return;
                    setState(() => _myReportsFilter = filter);
                  },
                  onReportTap: (report) =>
                      ReportDetailsDialog.show(context, report),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Report> _communityReports(List<Report> reports, String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return reports;
    return reports.where((report) => report.userId != currentUserId).toList();
  }

  List<SafetyAlert> _sortAlerts(List<SafetyAlert> alerts) {
    final sorted = [...alerts];
    sorted.sort((a, b) {
      final priorityCompare = _alertPriority(
        a.riskLevel,
      ).compareTo(_alertPriority(b.riskLevel));
      if (priorityCompare != 0) return priorityCompare;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return sorted;
  }

  int _alertPriority(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return 0;
      case 'warning':
        return 1;
      case 'watch':
        return 2;
      default:
        return 3;
    }
  }
}

class _MyReportsStreamView extends StatelessWidget {
  const _MyReportsStreamView({
    required this.currentUserId,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onReportTap,
  });

  final String? currentUserId;
  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final ValueChanged<Report> onReportTap;

  @override
  Widget build(BuildContext context) {
    final userId = currentUserId;

    if (userId == null || userId.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: EmptyNotifications(
            title: 'Log in to see your reports',
            message: 'Reports you submit will appear here after sign in.',
          ),
        ),
      );
    }

    return StreamBuilder<List<Report>>(
      stream: ReportFeedService.userReportsStream(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: RainGuardStateMessage(
                icon: Icons.assignment_outlined,
                title: 'Loading your reports',
                message: 'Checking reports submitted from this account.',
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: RainGuardStateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'My Reports unavailable',
                message: friendlyFirebaseError(
                  snapshot.error,
                  fallback: 'Unable to load your submitted reports.',
                ),
                iconColor: Colors.red.shade700,
              ),
            ),
          );
        }

        return _MyReportsView(
          reports: snapshot.data ?? const <Report>[],
          selectedFilter: selectedFilter,
          onFilterChanged: onFilterChanged,
          onReportTap: onReportTap,
        );
      },
    );
  }
}

class _NotificationTabSelector extends StatelessWidget {
  const _NotificationTabSelector({
    required this.selectedTab,
    required this.onChanged,
  });

  final _NotificationTab selectedTab;
  final ValueChanged<_NotificationTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RainGuardColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NotificationTabButton(
              icon: Icons.groups_rounded,
              isSelected: selectedTab == _NotificationTab.community,
              label: 'Community Updates',
              onTap: () => onChanged(_NotificationTab.community),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _NotificationTabButton(
              icon: Icons.assignment_outlined,
              isSelected: selectedTab == _NotificationTab.myReports,
              label: 'My Reports',
              onTap: () => onChanged(_NotificationTab.myReports),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTabButton extends StatelessWidget {
  const _NotificationTabButton({
    required this.icon,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : RainGuardColors.secondaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? RainGuardColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityUpdatesView extends StatelessWidget {
  const _CommunityUpdatesView({
    required this.alerts,
    required this.reports,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onReportTap,
  });

  final List<SafetyAlert> alerts;
  final List<Report> reports;
  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final ValueChanged<Report> onReportTap;

  @override
  Widget build(BuildContext context) {
    final showAlerts =
        selectedFilter == NotificationFilter.all ||
        selectedFilter == NotificationFilter.official;
    final showReports =
        selectedFilter == NotificationFilter.all ||
        selectedFilter == NotificationFilter.community;
    final isEmpty =
        (!showAlerts || alerts.isEmpty) && (!showReports || reports.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationFilterBar(
          selectedFilter: selectedFilter,
          options: [
            NotificationFilterOption(
              filter: NotificationFilter.all,
              icon: Icons.notifications_none_rounded,
              label: 'All',
              count: alerts.length + reports.length,
            ),
            NotificationFilterOption(
              filter: NotificationFilter.official,
              icon: Icons.shield_outlined,
              label: 'Official',
              count: alerts.length,
            ),
            NotificationFilterOption(
              filter: NotificationFilter.community,
              icon: Icons.groups_rounded,
              label: 'Community',
              count: reports.length,
            ),
          ],
          onChanged: onFilterChanged,
        ),
        if (showAlerts && alerts.isNotEmpty) ...[
          const SizedBox(height: 18),
          NotificationSectionHeader(
            'Official Advisories',
            count: alerts.length,
          ),
          const SizedBox(height: 10),
          ...alerts.map((alert) => SafetyAlertCard(alert: alert)),
        ],
        if (showReports && reports.isNotEmpty) ...[
          const SizedBox(height: 18),
          NotificationSectionHeader('Community Updates', count: reports.length),
          const SizedBox(height: 10),
          ...reports.map(
            (report) => NotificationReportCard(
              report: report,
              onTap: () => onReportTap(report),
            ),
          ),
        ],
        if (isEmpty) ...[
          const SizedBox(height: 22),
          const SizedBox(
            height: 300,
            child: Center(
              child: EmptyNotifications(
                title: 'No community updates yet',
                message:
                    'Official advisories and community reports will appear here.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MyReportsView extends StatelessWidget {
  const _MyReportsView({
    required this.reports,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onReportTap,
  });

  final List<Report> reports;
  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final ValueChanged<Report> onReportTap;

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filteredReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationFilterBar(
          selectedFilter: selectedFilter,
          options: [
            NotificationFilterOption(
              filter: NotificationFilter.all,
              icon: Icons.list_alt_rounded,
              label: 'All',
              count: reports.length,
            ),
            NotificationFilterOption(
              filter: NotificationFilter.pending,
              icon: Icons.pending_actions_rounded,
              label: 'Pending',
              count: reports.where(_isPending).length,
            ),
            NotificationFilterOption(
              filter: NotificationFilter.verified,
              icon: Icons.verified_user_outlined,
              label: 'Verified',
              count: reports.where((report) => report.isAdminVerified).length,
            ),
            NotificationFilterOption(
              filter: NotificationFilter.resolved,
              icon: Icons.check_circle_outline_rounded,
              label: 'Resolved',
              count: reports.where((report) => report.isResolved).length,
            ),
          ],
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 18),
        NotificationSectionHeader('My Reports', count: filteredReports.length),
        const SizedBox(height: 10),
        if (filteredReports.isEmpty)
          const SizedBox(
            height: 300,
            child: Center(
              child: EmptyNotifications(
                title: 'No submitted reports yet',
                message:
                    'Reports you submit will appear here with review progress.',
              ),
            ),
          )
        else
          ...filteredReports.map(
            (report) =>
                MyReportCard(report: report, onTap: () => onReportTap(report)),
          ),
      ],
    );
  }

  List<Report> get _filteredReports {
    switch (selectedFilter) {
      case NotificationFilter.pending:
        return reports.where(_isPending).toList();
      case NotificationFilter.verified:
        return reports.where((report) => report.isAdminVerified).toList();
      case NotificationFilter.resolved:
        return reports.where((report) => report.isResolved).toList();
      case NotificationFilter.all:
      case NotificationFilter.official:
      case NotificationFilter.community:
        return reports;
    }
  }

  bool _isPending(Report report) {
    return !report.isAdminVerified && !report.isResolved && !report.isRejected;
  }
}
