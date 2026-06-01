import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_draft.dart';
import '../models/report_model.dart';
import '../services/report_draft_service.dart';
import '../services/report_feed_service.dart';
import '../services/report_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/firebase_error_messages.dart';
import '../utils/location_constants.dart';
import '../widgets/map/pending_draft_sheet.dart';
import '../widgets/map/report_map_card.dart';
import '../widgets/map/selected_report_preview_card.dart';
import '../widgets/rainguard_app_bar.dart';
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
  String _selectedReportId = '';
  bool _isRetryingDrafts = false;
  MapReportFilter _activeFilter = MapReportFilter.active;

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

  Stream<List<Report>> get _reportsStream =>
      ReportFeedService.activeMapReportsStream();

  void _handleDraftCountChanged() {
    _loadPendingDrafts();
  }

  Future<void> _loadPendingDrafts() async {
    final drafts = await ReportDraftService.getPendingDrafts();
    if (!mounted) return;
    setState(() => _pendingDrafts = drafts);
  }

  void _showReportDetails(Report report) {
    ReportDetailsDialog.show(context, report);
  }

  void _selectReport(Report report) {
    setState(() => _selectedReportId = report.id);
  }

  void _clearSelectedReport() {
    setState(() => _selectedReportId = '');
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
      builder: (context) => PendingDraftSheet(
        draft: draft,
        isRetrying: _isRetryingDrafts,
        onRetryTap: _retryPendingDrafts,
      ),
    );
  }

  Future<void> _retryPendingDrafts() async {
    if (_isRetryingDrafts) return;

    Navigator.of(context).maybePop();
    setState(() => _isRetryingDrafts = true);

    final submittedCount = await ReportService.submitPendingDrafts();
    await _loadPendingDrafts();

    if (!mounted) return;
    setState(() => _isRetryingDrafts = false);

    final message = submittedCount > 0
        ? '$submittedCount pending report uploaded.'
        : 'Draft is still saved locally. Check your connection and try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<List<Report>>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <Report>[];
          final filteredReports = _filteredReports(reports);
          final selectedReport = _selectedReport(filteredReports);
          final hasSelectedReport = selectedReport != null;

          return Stack(
            children: [
              Positioned.fill(
                child: ReportMapCard(
                  mapController: _mapController,
                  initialCenter: _calambaCenter,
                  reports: filteredReports,
                  pendingDrafts: _pendingDrafts,
                  activeFilter: _activeFilter,
                  onFilterChanged: _setFilter,
                  onReportTap: _selectReport,
                  onPendingDraftTap: _showPendingDraftDetails,
                  onAddTap: _showAddReportModal,
                  addButtonBottom: hasSelectedReport ? 206 : 22,
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  reports.isEmpty)
                const Positioned(top: 16, right: 16, child: _MapLoadingBadge()),
              if (selectedReport != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: SelectedReportPreviewCard(
                      report: selectedReport,
                      onClose: _clearSelectedReport,
                      onViewDetails: () => _showReportDetails(selectedReport),
                    ),
                  ),
                ),
              if (filteredReports.isEmpty &&
                  snapshot.connectionState != ConnectionState.waiting)
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: SafeArea(top: false, child: _EmptyMapHint()),
                ),
              if (snapshot.hasError)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _MapErrorBanner(
                    message: friendlyFirebaseError(
                      snapshot.error,
                      fallback: 'Unable to load map reports.',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Report? _selectedReport(List<Report> reports) {
    if (_selectedReportId.isEmpty) return null;

    for (final report in reports) {
      if (report.id == _selectedReportId) return report;
    }

    return null;
  }

  List<Report> _filteredReports(List<Report> reports) {
    switch (_activeFilter) {
      case MapReportFilter.rain:
        return reports
            .where((report) => report.type == ReportType.rain)
            .toList();
      case MapReportFilter.flood:
        return reports
            .where((report) => report.type == ReportType.flood)
            .toList();
      case MapReportFilter.verified:
        return reports.where((report) => report.isAdminVerified).toList();
      case MapReportFilter.active:
        return reports;
    }
  }

  void _setFilter(MapReportFilter filter) {
    setState(() {
      _activeFilter = filter;
      _selectedReportId = '';
    });
  }
}

class _MapLoadingBadge extends StatelessWidget {
  const _MapLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading reports',
              style: TextStyle(
                color: RainGuardColors.ink,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyMapHint extends StatelessWidget {
  const _EmptyMapHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: RainGuardColors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No community reports yet. Tap + to submit a rain or flood report.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: RainGuardColors.secondaryText,
            fontSize: 9,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
