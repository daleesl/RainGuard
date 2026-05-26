import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';

class ReportTypeSection extends StatelessWidget {
  const ReportTypeSection({
    required this.selectedFloodLevel,
    required this.selectedType,
    required this.onFloodLevelChanged,
    required this.onTypeChanged,
    super.key,
  });

  static const List<String> floodLevels = [
    'ankle level',
    'knee level',
    'waist level',
    'above waist level',
  ];

  final String? selectedFloodLevel;
  final ReportType selectedType;
  final ValueChanged<String?> onFloodLevelChanged;
  final ValueChanged<ReportType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;

            return Row(
              children: [
                _ReportTypeCard(
                  isSelected: selectedType == ReportType.rain,
                  onTap: () => onTypeChanged(ReportType.rain),
                  type: ReportType.rain,
                  width: cardWidth,
                ),
                const SizedBox(width: 10),
                _ReportTypeCard(
                  isSelected: selectedType == ReportType.flood,
                  onTap: () => onTypeChanged(ReportType.flood),
                  type: ReportType.flood,
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (selectedType == ReportType.flood) ...[
          const Text(
            'Flood Level',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedFloodLevel,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: floodLevels
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(
                      level[0].toUpperCase() + level.substring(1),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: onFloodLevelChanged,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({
    required this.isSelected,
    required this.onTap,
    required this.type,
    required this.width,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final ReportType type;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? RainGuardColors.softBlue : Colors.white,
          border: Border.all(
            color: isSelected ? RainGuardColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              MapHelper.getReportIcon(type),
              color: isSelected ? RainGuardColors.primary : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                MapHelper.getReportTypeName(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? RainGuardColors.primary : Colors.black87,
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
