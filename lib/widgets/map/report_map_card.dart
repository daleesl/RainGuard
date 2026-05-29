import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../models/report_draft.dart';
import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/location_constants.dart';
import '../intelligent_pin.dart';

class ReportMapCard extends StatelessWidget {
  const ReportMapCard({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.reports,
    required this.pendingDrafts,
    required this.onReportTap,
    required this.onPendingDraftTap,
    required this.onAddTap,
    this.addButtonBottom = 22,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<Report> reports;
  final List<ReportDraft> pendingDrafts;
  final ValueChanged<Report> onReportTap;
  final ValueChanged<ReportDraft> onPendingDraftTap;
  final VoidCallback onAddTap;
  final double addButtonBottom;

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

    return Stack(
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
                zoomToBoundsOnClick: false,
                spiderfyCluster: true,
                spiderfyCircleRadius: 34,
                spiderfySpiralDistanceMultiplier: 1,
                circleSpiralSwitchover: 7,
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
          right: 18,
          bottom: addButtonBottom,
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
