import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../models/report_draft.dart';
import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/location_constants.dart';
import '../../utils/map_report_filter.dart';
import '../../utils/monitoring_area.dart';
import '../intelligent_pin.dart';
import 'map_filter_pill.dart';
import 'map_overlay_label.dart';

class ReportMapCard extends StatelessWidget {
  const ReportMapCard({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.reports,
    required this.pendingDrafts,
    required this.activeFilter,
    required this.isBoundaryVisible,
    required this.onFilterChanged,
    required this.onToggleBoundary,
    required this.onReportTap,
    required this.onPendingDraftTap,
    required this.onAddTap,
    this.addButtonBottom = 22,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<Report> reports;
  final List<ReportDraft> pendingDrafts;
  final MapReportFilter activeFilter;
  final bool isBoundaryVisible;
  final ValueChanged<MapReportFilter> onFilterChanged;
  final ValueChanged<bool> onToggleBoundary;
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
            if (isBoundaryVisible)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: linggaMonitoringBoundary,
                    color: RainGuardColors.primary.withOpacity(0.06),
                    borderColor: RainGuardColors.primary.withOpacity(0.62),
                    borderStrokeWidth: 1.4,
                  ),
                ],
              ),
            if (isBoundaryVisible)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 188,
                    height: 28,
                    point: linggaMonitoringAreaLabelPoint,
                    child: const MapOverlayLabel(
                      label: linggaMonitoringAreaLabel,
                    ),
                  ),
                ],
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
                  return _ReportClusterMarker(count: clusteredMarkers.length);
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
          right: 14,
          child: Row(
            children: [
              _MapBadge(
                count: reports.length,
                pendingCount: pendingDrafts.length,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MapFilterBar(
                  activeFilter: activeFilter,
                  onChanged: onFilterChanged,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 14,
          right: 14,
          child: _BoundaryToolbar(
            isVisible: isBoundaryVisible,
            onChanged: onToggleBoundary,
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

class _MapFilterBar extends StatelessWidget {
  const _MapFilterBar({required this.activeFilter, required this.onChanged});

  final MapReportFilter activeFilter;
  final ValueChanged<MapReportFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DecoratedBox(
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
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapFilterPill(
                      filter: MapReportFilter.active,
                      isActive: activeFilter == MapReportFilter.active,
                      label: 'Active',
                      onChanged: onChanged,
                    ),
                    MapFilterPill(
                      filter: MapReportFilter.rain,
                      isActive: activeFilter == MapReportFilter.rain,
                      label: 'Rain',
                      onChanged: onChanged,
                    ),
                    MapFilterPill(
                      filter: MapReportFilter.flood,
                      isActive: activeFilter == MapReportFilter.flood,
                      label: 'Flood',
                      onChanged: onChanged,
                    ),
                    MapFilterPill(
                      filter: MapReportFilter.verified,
                      isActive: activeFilter == MapReportFilter.verified,
                      label: 'Verified',
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoundaryToolbar extends StatelessWidget {
  const _BoundaryToolbar({
    required this.isVisible,
    required this.onChanged,
  });

  final bool isVisible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _BoundaryToggle(
        isVisible: isVisible,
        onChanged: onChanged,
      ),
    );
  }
}

class _BoundaryToggle extends StatelessWidget {
  const _BoundaryToggle({
    required this.isVisible,
    required this.onChanged,
  });

  final bool isVisible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: () => onChanged(!isVisible),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: RainGuardColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVisible
                    ? Icons.layers_rounded
                    : Icons.layers_clear_rounded,
                size: 13,
                color: isVisible
                    ? RainGuardColors.primary
                    : RainGuardColors.secondaryText,
              ),
              const SizedBox(width: 5),
              Text(
                'Boundary',
                style: TextStyle(
                  color: isVisible
                      ? RainGuardColors.primary
                      : RainGuardColors.secondaryText,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.count, required this.pendingCount});

  final int count;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
            size: 14,
            color: RainGuardColors.primary,
          ),
          const SizedBox(width: 5),
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
