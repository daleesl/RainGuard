import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';

class SelectedReportPreviewCard extends StatelessWidget {
  const SelectedReportPreviewCard({
    super.key,
    required this.report,
    required this.onClose,
    required this.onViewDetails,
  });

  final Report report;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final color = MapHelper.getReportColor(report);
    final imageUrl = report.allImageUrls.isNotEmpty
        ? report.allImageUrls.first
        : null;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: RainGuardColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _PreviewChip(
                            color: color,
                            label:
                                '${MapHelper.getReportTypeName(report.type)} report',
                          ),
                          if (report.isAdminVerified)
                            const _VerifiedChip(),
                          _PreviewChip(
                            color: Colors.blueGrey.shade600,
                            label: MapHelper.getFreshnessName(report.freshness),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report.locationName ?? 'Location name unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainGuardColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(report.createdAt),
                        style: const TextStyle(
                          color: RainGuardColors.secondaryText,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PhotoThumb(
                  color: color,
                  imageUrl: imageUrl,
                  reportType: report.type,
                ),
                const SizedBox(width: 6),
                IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: RainGuardColors.secondaryText,
                  tooltip: 'Close preview',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.description.isNotEmpty
                  ? report.description
                  : 'No description provided.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RainGuardColors.ink,
                fontSize: 9,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text('View Details'),
                style: FilledButton.styleFrom(
                  backgroundColor: RainGuardColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.color,
    required this.imageUrl,
    required this.reportType,
  });

  final String? imageUrl;
  final Color color;
  final ReportType reportType;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 62,
        height: 62,
        color: color.withOpacity(0.10),
        child: imageUrl == null
            ? Icon(
                MapHelper.getReportIcon(reportType),
                color: color,
                size: 26,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  color: color,
                  size: 24,
                ),
              ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.green.shade700,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
