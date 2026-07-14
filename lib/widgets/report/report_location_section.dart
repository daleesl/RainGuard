import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/rainguard_theme.dart';

enum ReportLocationMode { gps, manual }

class ReportLocationSection extends StatelessWidget {
  const ReportLocationSection({
    required this.mode,
    required this.manualLocation,
    required this.manualLocationName,
    required this.isResolvingManualLocation,
    required this.onChooseManualLocation,
    required this.onUseCurrentGps,
    super.key,
  });

  final ReportLocationMode mode;
  final LatLng? manualLocation;
  final String? manualLocationName;
  final bool isResolvingManualLocation;
  final VoidCallback onChooseManualLocation;
  final VoidCallback onUseCurrentGps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LocationChoiceCard(
                icon: Icons.my_location_rounded,
                label: 'Current GPS',
                isSelected: mode == ReportLocationMode.gps,
                onTap: onUseCurrentGps,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocationChoiceCard(
                icon: Icons.add_location_alt_outlined,
                label: 'Choose on map',
                isSelected: mode == ReportLocationMode.manual,
                onTap: onChooseManualLocation,
              ),
            ),
          ],
        ),
        if (mode == ReportLocationMode.manual) ...[
          const SizedBox(height: 10),
          _ManualLocationSummary(
            location: manualLocation,
            locationName: manualLocationName,
            isResolving: isResolvingManualLocation,
            onChangeTap: onChooseManualLocation,
          ),
        ],
      ],
    );
  }
}

class _LocationChoiceCard extends StatelessWidget {
  const _LocationChoiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? RainGuardColors.softBlue.withValues(alpha: 0.78)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? RainGuardColors.primary
                  : RainGuardColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? RainGuardColors.primary
                    : RainGuardColors.secondaryText,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected
                          ? RainGuardColors.primary
                          : RainGuardColors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualLocationSummary extends StatelessWidget {
  const _ManualLocationSummary({
    required this.location,
    required this.locationName,
    required this.isResolving,
    required this.onChangeTap,
  });

  final LatLng? location;
  final String? locationName;
  final bool isResolving;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final displayText = location == null
        ? 'No map point selected yet'
        : isResolving
            ? 'Finding location name...'
            : locationName ?? 'Location name unavailable';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RainGuardColors.warningFill.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RainGuardColors.warningText.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            location == null
                ? Icons.location_searching_rounded
                : Icons.location_on_rounded,
            color: RainGuardColors.warningText,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manually selected location',
                  style: TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeTap,
            style: TextButton.styleFrom(
              foregroundColor: RainGuardColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
            child: Text(location == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
  }
}
