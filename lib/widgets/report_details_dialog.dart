import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/report_model.dart';
import '../theme/rainguard_theme.dart';
import '../utils/map_helper.dart';

class ReportDetailsDialog {
  static void show(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsSheet(report: report),
    );
  }
}

class _ReportDetailsSheet extends StatelessWidget {
  const _ReportDetailsSheet({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final riskColor = MapHelper.getRiskColor(report.risk);
    final freshnessColor = MapHelper.getReportColor(report);
    final reportName = MapHelper.getReportTypeName(report.type);
    final reporterName = report.reporterName ?? 'Anonymous reporter';
    final freshnessLabel = MapHelper.getFreshnessName(report.freshness);
    final statusTimeLabel =
        '$freshnessLabel - ${timeago.format(report.createdAt)}';
    final createdLabel = _formatReportDateTime(report.createdAt);
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
              Center(
                child: Container(
                  width: 44,
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
              ),
              const SizedBox(height: 18),
              _ReportImageGallery(imageUrls: report.allImageUrls),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Description',
                icon: Icons.description_outlined,
                child: Text(
                  report.description.isNotEmpty
                      ? report.description
                      : 'No description provided for this report.',
                  style: const TextStyle(
                    height: 1.45,
                    fontSize: 10,
                    color: RainGuardColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Location',
                icon: Icons.place_outlined,
                child: Text(
                  report.locationName ?? 'Exact name unavailable',
                  style: const TextStyle(
                    fontSize: 12,
                    color: RainGuardColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                      value: imageCount == 1
                          ? '1 attached'
                          : '$imageCount attached',
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
              const SizedBox(height: 20),
              SizedBox(
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
              ),
            ],
          ),
        );
      },
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

class _ReportImageGallery extends StatefulWidget {
  const _ReportImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ReportImageGallery> createState() => _ReportImageGalleryState();
}

class _ReportImageGalleryState extends State<_ReportImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.imageUrls;

    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: imageUrls.isNotEmpty
          ? Stack(
              children: [
                PageView.builder(
                  itemCount: imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _FullScreenImageViewer.show(
                        context,
                        imageUrls: imageUrls,
                        initialIndex: index,
                      ),
                      child: _NetworkReportImage(imageUrl: imageUrls[index]),
                    );
                  },
                ),
                if (imageUrls.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                if (imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == _currentIndex ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const _EmptyImageState(
              icon: Icons.image_not_supported_outlined,
              label: 'No image attached',
            ),
    );
  }
}

class _NetworkReportImage extends StatelessWidget {
  const _NetworkReportImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const _EmptyImageState(
          icon: Icons.broken_image_outlined,
          label: 'Image could not be loaded',
        );
      },
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    required int initialIndex,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => _FullScreenImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const _EmptyImageState(
                          icon: Icons.broken_image_outlined,
                          label: 'Image could not be loaded',
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: Colors.blueGrey.shade200),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: RainGuardColors.secondaryText,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.emphasizeLabel = false,
  });

  final String label;
  final String value;
  final bool emphasizeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: emphasizeLabel
                  ? RainGuardColors.primary
                  : RainGuardColors.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: RainGuardColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: RainGuardColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: RainGuardColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
