import 'package:flutter/material.dart';
import '../models/report_model.dart';
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
    final reportName = MapHelper.getReportTypeName(report.type);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FAFD),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102033),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Reported by ${report.userId ?? 'Anonymous'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF697B8C),
                            fontSize: 13,
                          ),
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
              _ReportImage(imageUrl: report.imageUrl),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Risk level',
                      value: MapHelper.getRiskLevelName(report.risk),
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Flood level',
                      value: report.floodLevel ?? 'Not set',
                      color: Colors.blueAccent.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Latitude',
                      value: report.latitude.toStringAsFixed(5),
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Longitude',
                      value: report.longitude.toStringAsFixed(5),
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
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
                    fontSize: 15,
                    color: Color(0xFF102033),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Report time',
                icon: Icons.access_time_rounded,
                child: Text(
                  report.createdAt.toString().split('.').first,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF102033),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

class _ReportImage extends StatelessWidget {
  const _ReportImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E7EF)),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
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
            )
          : const _EmptyImageState(
              icon: Icons.image_not_supported_outlined,
              label: 'No image attached',
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
        Text(label, style: const TextStyle(color: Color(0xFF697B8C))),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF697B8C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w800,
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
        border: Border.all(color: const Color(0xFFD9E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueAccent.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF102033),
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
