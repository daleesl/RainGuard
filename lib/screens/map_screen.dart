import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/report_model.dart';
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

  Stream<QuerySnapshot> get _reportsStream => FirebaseFirestore.instance
      .collection('reports')
      .orderBy('created_at', descending: true)
      .snapshots();

  void _showReportDetails(Report report) {
    ReportDetailsDialog.show(context, report);
  }

  void _showAddReportModal() {
    showModalBottomSheet(
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
                onReportTap: _showReportDetails,
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
    required this.onReportTap,
    required this.onAddTap,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<Report> reports;
  final ValueChanged<Report> onReportTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
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
              MarkerLayer(
                markers: reports
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
                    .toList(),
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _MapBadge(count: reports.length),
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

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.count});

  final int count;

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
            '$count live reports',
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
    final color = MapHelper.getRiskColor(report.risk);
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
                      timeago.format(report.createdAt),
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
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
