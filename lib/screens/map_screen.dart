import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/report_draft.dart';
import '../models/report_model.dart';
import '../services/report_draft_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/location_constants.dart';
import '../utils/map_helper.dart';
import '../widgets/intelligent_pin.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_card.dart';
import '../widgets/report_details_dialog.dart';
import '../widgets/report_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _calambaCenter = LatLng(
    RainGuardCoverage.calambaMapLatitude,
    RainGuardCoverage.calambaMapLongitude,
  );

  final MapController _mapController = MapController();
  List<ReportDraft> _pendingDrafts = const [];

  @override
  void initState() {
    super.initState();
    ReportDraftService.pendingDraftCount.addListener(_handleDraftCountChanged);
    _loadPendingDrafts();
  }

  @override
  void dispose() {
    ReportDraftService.pendingDraftCount.removeListener(
      _handleDraftCountChanged,
    );
    super.dispose();
  }

  void _handleDraftCountChanged() {
    _loadPendingDrafts();
  }

  Future<void> _loadPendingDrafts() async {
    final drafts = await ReportDraftService.getPendingDrafts();
    if (!mounted) return;
    setState(() => _pendingDrafts = drafts);
  }

  Stream<QuerySnapshot> get _reportsStream => FirebaseFirestore.instance
      .collection('reports')
      .orderBy('created_at', descending: true)
      .snapshots();

  void _showReportDetails(Report report) {
    ReportDetailsDialog.show(context, report);
  }

  Future<void> _showAddReportModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ReportModal(),
      ),
    );
    await _loadPendingDrafts();
  }

  void _showPendingDraftDetails(ReportDraft draft) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PendingDraftSheet(draft: draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          final reports = _parseReports(snapshot.data?.docs ?? []);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Flood Map',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: RainGuardColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _MapCard(
                mapController: _mapController,
                initialCenter: _calambaCenter,
                reports: reports,
                pendingDrafts: _pendingDrafts,
                onReportTap: _showReportDetails,
                onPendingDraftTap: _showPendingDraftDetails,
                onAddTap: _showAddReportModal,
              ),
              const SizedBox(height: 16),
              _LegendCard(),
              const SizedBox(height: 16),
              _RecentReportsCard(
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                reports: reports,
                onReportTap: _showReportDetails,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Report> _parseReports(List<QueryDocumentSnapshot> docs) {
    final reports = <Report>[];

    for (final doc in docs) {
      try {
        reports.add(
          Report.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
        );
      } catch (e) {
        debugPrint('Error parsing report ${doc.id}: $e');
      }
    }

    return reports;
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.mapController,
    required this.initialCenter,
    required this.reports,
    required this.pendingDrafts,
    required this.onReportTap,
    required this.onPendingDraftTap,
    required this.onAddTap,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<Report> reports;
  final List<ReportDraft> pendingDrafts;
  final ValueChanged<Report> onReportTap;
  final ValueChanged<ReportDraft> onPendingDraftTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final markers = reports
        .map(
          (report) => Marker(
            width: 60,
            height: 60,
            point: LatLng(report.latitude, report.longitude),
            child: GestureDetector(
              onTap: () => onReportTap(report),
              child: IntelligentPin(report: report),
            ),
          ),
        )
        .toList();

    return RainGuardCard(
      height: 310,
      padding: EdgeInsets.zero,
      radius: 22,
      clipBehavior: Clip.hardEdge,
      shadowOpacity: 0.10,
      blurRadius: 24,
      shadowOffset: const Offset(0, 12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: RainGuardCoverage.calambaMapZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.rainguard',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 48,
                  size: const Size(46, 46),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(36),
                  maxZoom: 17,
                  markers: markers,
                  showPolygon: false,
                  builder: (context, clusteredMarkers) {
                    return _ReportClusterMarker(
                      count: clusteredMarkers.length,
                    );
                  },
                ),
              ),
              MarkerLayer(
                markers: pendingDrafts
                    .map(
                      (draft) => Marker(
                        width: 54,
                        height: 54,
                        point: draft.point,
                        child: GestureDetector(
                          onTap: () => onPendingDraftTap(draft),
                          child: const _PendingDraftMarker(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _MapBadge(
              count: reports.length,
              pendingCount: pendingDrafts.length,
            ),
          ),
          Positioned(
            bottom: 18,
            right: 18,
            child: FloatingActionButton(
              heroTag: 'add-report-map',
              onPressed: onAddTap,
              backgroundColor: RainGuardColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportClusterMarker extends StatelessWidget {
  const _ReportClusterMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RainGuardColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: RainGuardColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PendingDraftMarker extends StatelessWidget {
  const _PendingDraftMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade800,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade800.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(
        Icons.schedule_send_outlined,
        color: Colors.white,
        size: 23,
      ),
    );
  }
}

class _PendingDraftSheet extends StatelessWidget {
  const _PendingDraftSheet({required this.draft});

  final ReportDraft draft;

  @override
  Widget build(BuildContext context) {
    final typeName = MapHelper.getReportTypeName(draft.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: RainGuardColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.amber.shade800.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.schedule_send_outlined,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending $typeName report',
                      style: const TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Saved locally. It will appear to others after upload.',
                      style: TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            draft.description.isEmpty
                ? 'No description added.'
                : draft.description,
            style: const TextStyle(
              color: RainGuardColors.ink,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _PendingDraftMetaPill(
            color: Colors.amber.shade800,
            icon: Icons.access_time_rounded,
            label: timeago.format(draft.createdAt),
          ),
        ],
      ),
    );
  }
}

class _PendingDraftMetaPill extends StatelessWidget {
  const _PendingDraftMetaPill({
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
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

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.count, required this.pendingCount});

  final int count;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pin_drop_rounded,
            size: 16,
            color: RainGuardColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            pendingCount > 0
                ? '$count live, $pendingCount pending'
                : '$count live reports',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: RainGuardColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RainGuardCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: RainGuardColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LegendChip(color: Colors.red.shade600, label: 'Flood'),
              _LegendChip(color: Colors.amber.shade600, label: 'Risk'),
              _LegendChip(color: Colors.green.shade600, label: 'Safe'),
              _LegendChip(color: RainGuardColors.primary, label: 'Active'),
              _LegendChip(color: Colors.blueGrey.shade400, label: 'Recent'),
              _LegendChip(color: Colors.blueGrey.shade300, label: 'Archived'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard({
    required this.isLoading,
    required this.reports,
    required this.onReportTap,
  });

  final bool isLoading;
  final List<Report> reports;
  final ValueChanged<Report> onReportTap;

  @override
  Widget build(BuildContext context) {
    final visibleReports = reports.take(4).toList();

    return RainGuardCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reports',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: RainGuardColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visibleReports.isEmpty)
            const _EmptyReports()
          else
            ...visibleReports.map(
              (report) => _RecentReportTile(
                report: report,
                onTap: () => onReportTap(report),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  const _RecentReportTile({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = MapHelper.getReportColor(report);
    final freshnessLabel = MapHelper.getFreshnessName(report.freshness);
    final title = '${MapHelper.getReportTypeName(report.type)} reported';
    final reporterName = report.reporterName ?? 'Anonymous reporter';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  MapHelper.getReportIcon(report.type),
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: RainGuardColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'By $reporterName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.description.isNotEmpty
                          ? report.description
                          : 'Tap to view report details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${timeago.format(report.createdAt)} - $freshnessLabel',
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RainGuardColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No community reports yet. New reports will appear here once submitted.',
        style: TextStyle(color: Color(0xFF0B3A5B), fontSize: 8, height: 1.35),
      ),
    );
  }
}
