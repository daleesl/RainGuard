import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';

class ReportTypeSection extends StatelessWidget {
  const ReportTypeSection({
    required this.selectedFloodLevel,
    required this.selectedRainIntensity,
    required this.selectedType,
    required this.onFloodLevelChanged,
    required this.onRainIntensityChanged,
    required this.onTypeChanged,
    super.key,
  });

  static const List<String> rainIntensities = [
    'Light rain',
    'Moderate rain',
    'Heavy rain',
  ];

  static const List<String> floodLevels = [
    'Ankle level - up to 20 cm',
    'Knee level - around 21-50 cm',
    'Waist level - around 51-100 cm',
    'Chest level or higher - above 100 cm',
  ];

  final String? selectedFloodLevel;
  final String? selectedRainIntensity;
  final ReportType selectedType;
  final ValueChanged<String?> onFloodLevelChanged;
  final ValueChanged<String?> onRainIntensityChanged;
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
        if (selectedType == ReportType.rain) ...[
          const Text(
            'Rain Intensity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedRainIntensity,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select rain intensity',
              hintStyle: const TextStyle(fontSize: 12),
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
            items: rainIntensities
                .map(
                  (intensity) => DropdownMenuItem(
                    value: intensity,
                    child: Text(
                      intensity,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: onRainIntensityChanged,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == ReportType.flood) ...[
          const Text(
            'Estimated Flood Water',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedFloodLevel,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select estimated flood water',
              hintStyle: const TextStyle(fontSize: 12),
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
                      level,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: onFloodLevelChanged,
          ),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Estimate only from a safe location. ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: 'Do not enter floodwater to measure it.'),
              ],
            ),
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
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
