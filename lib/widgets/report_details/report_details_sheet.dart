part of '../report_details_dialog.dart';

class _ReportDetailsSheet extends StatelessWidget {
  const _ReportDetailsSheet({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final reportName = MapHelper.getReportTypeName(report.type);
    final reporterName = report.reporterName ?? 'Anonymous reporter';
    final imageCount = report.allImageUrls.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: RainGuardColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              _ReportDetailsHeader(
                report: report,
                reportName: reportName,
                reporterName: reporterName,
              ),
              const SizedBox(height: 18),
              _ReportImageGallery(imageUrls: report.allImageUrls),
              const SizedBox(height: 18),
              _ReportDescriptionSection(description: report.description),
              const SizedBox(height: 12),
              _ReportLocationSection(locationName: report.locationName),
              const SizedBox(height: 18),
              _ReportDetailsInfoGrid(
                report: report,
                reporterName: reporterName,
                imageCount: imageCount,
              ),
              const SizedBox(height: 20),
              const _DoneButton(),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade200,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ReportDetailsHeader extends StatelessWidget {
  const _ReportDetailsHeader({
    required this.report,
    required this.reportName,
    required this.reporterName,
  });

  final Report report;
  final String reportName;
  final String reporterName;

  @override
  Widget build(BuildContext context) {
    final riskColor = MapHelper.getRiskColor(report.risk);
    final freshnessColor = MapHelper.getReportColor(report);
    final freshnessLabel = MapHelper.getFreshnessName(report.freshness);
    final statusTimeLabel =
        '$freshnessLabel - ${timeago.format(report.createdAt)}';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            MapHelper.getReportIcon(report.type),
            color: riskColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$reportName Report',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: RainGuardColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Reported by $reporterName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RainGuardColors.secondaryText,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _StatusPill(
                    color: riskColor,
                    icon: MapHelper.getReportIcon(report.type),
                    label: reportName,
                  ),
                  _StatusPill(
                    color: freshnessColor,
                    icon: Icons.schedule_rounded,
                    label: statusTimeLabel,
                  ),
                  if (report.isAdminVerified)
                    const _StatusPill(
                      color: RainGuardColors.success,
                      icon: Icons.verified_rounded,
                      label: 'Verified by admin',
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _ReportDescriptionSection extends StatelessWidget {
  const _ReportDescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Description',
      icon: Icons.description_outlined,
      child: Text(
        description.isNotEmpty
            ? description
            : 'No description provided for this report.',
        style: const TextStyle(
          height: 1.45,
          fontSize: 10,
          color: RainGuardColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ReportLocationSection extends StatelessWidget {
  const _ReportLocationSection({required this.locationName});

  final String? locationName;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Location',
      icon: Icons.place_outlined,
      child: Text(
        locationName ?? 'Exact name unavailable',
        style: const TextStyle(
          fontSize: 12,
          color: RainGuardColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportDetailsInfoGrid extends StatelessWidget {
  const _ReportDetailsInfoGrid({
    required this.report,
    required this.reporterName,
    required this.imageCount,
  });

  final Report report;
  final String reporterName;
  final int imageCount;

  @override
  Widget build(BuildContext context) {
    final createdLabel = _formatReportDateTime(report.createdAt);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Risk level',
                value: MapHelper.getRiskLevelName(report.risk),
                emphasizeLabel: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                label: 'Photos',
                value: imageCount == 1 ? '1 attached' : '$imageCount attached',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Reporter',
                value: reporterName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                label: 'Created',
                value: createdLabel,
              ),
            ),
          ],
        ),
        if (report.floodLevel != null) ...[
          const SizedBox(height: 12),
          _InfoTile(label: 'Flood level', value: report.floodLevel!),
        ],
      ],
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: RainGuardColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text(
          'Done',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _formatReportDateTime(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour == 0 || date.hour == 12 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
}
