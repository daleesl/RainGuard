import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../utils/map_helper.dart';

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory ReportStatusChip.type(Report report) {
    return ReportStatusChip(
      color: MapHelper.getReportColor(report),
      label: '${MapHelper.getReportTypeName(report.type)} report',
    );
  }

  factory ReportStatusChip.freshness(Report report) {
    return ReportStatusChip(
      color: Colors.blueGrey.shade600,
      label: MapHelper.getFreshnessName(report.freshness),
    );
  }

  const ReportStatusChip.verified({super.key})
    : label = 'Verified',
      color = Colors.green,
      icon = Icons.verified_rounded;

  final String label;
  final Color color;
  final IconData? icon;

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
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
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
