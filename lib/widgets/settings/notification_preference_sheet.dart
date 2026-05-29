import 'package:flutter/material.dart';

import '../../services/notification_preference_service.dart';
import '../../theme/rainguard_theme.dart';

class NotificationPreferenceSelection {
  const NotificationPreferenceSelection({
    required this.preference,
    required this.nearbyRadiusKm,
  });

  final NotificationPreference preference;
  final double nearbyRadiusKm;
}

class NotificationPreferenceSheet extends StatefulWidget {
  const NotificationPreferenceSheet({
    super.key,
    required this.selectedPreference,
    required this.selectedRadiusKm,
  });

  final NotificationPreference selectedPreference;
  final double selectedRadiusKm;

  @override
  State<NotificationPreferenceSheet> createState() =>
      _NotificationPreferenceSheetState();
}

class _NotificationPreferenceSheetState
    extends State<NotificationPreferenceSheet> {
  late NotificationPreference _selectedPreference;
  late double _selectedRadiusKm;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.selectedPreference;
    _selectedRadiusKm = widget.selectedRadiusKm;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: RainGuardColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),
          const Text(
            'Notification Type',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose which community reports should alert this device.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ...NotificationPreference.values.map(
            (preference) => _NotificationPreferenceOption(
              preference: preference,
              selectedRadiusKm: _selectedRadiusKm,
              isSelected: _selectedPreference == preference,
              onRadiusChanged: (radiusKm) {
                setState(() {
                  _selectedPreference = NotificationPreference.nearbyOnly;
                  _selectedRadiusKm = radiusKm;
                });
              },
              onTap: () {
                setState(() => _selectedPreference = preference);
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  NotificationPreferenceSelection(
                    preference: _selectedPreference,
                    nearbyRadiusKm: _selectedRadiusKm,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: RainGuardColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Preference',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPreferenceOption extends StatelessWidget {
  const _NotificationPreferenceOption({
    required this.preference,
    required this.isSelected,
    required this.selectedRadiusKm,
    required this.onRadiusChanged,
    required this.onTap,
  });

  final NotificationPreference preference;
  final bool isSelected;
  final double selectedRadiusKm;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? RainGuardColors.softBlue : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? RainGuardColors.primary
                    : RainGuardColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RainGuardColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _preferenceIcon(preference),
                        color: RainGuardColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preference.label,
                            style: const TextStyle(
                              color: RainGuardColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            preference.description,
                            style: const TextStyle(
                              color: RainGuardColors.secondaryText,
                              fontSize: 8,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RainGuardColors.primary,
                      ),
                  ],
                ),
                if (preference == NotificationPreference.nearbyOnly &&
                    isSelected) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final radiusKm
                          in NotificationPreferenceService.nearbyRadiusOptionsKm)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: radiusKm == 5 ? 0 : 8,
                            ),
                            child: _RadiusChoiceChip(
                              radiusKm: radiusKm,
                              isSelected: selectedRadiusKm == radiusKm,
                              onTap: () => onRadiusChanged(radiusKm),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _preferenceIcon(NotificationPreference preference) {
    switch (preference) {
      case NotificationPreference.allReports:
        return Icons.notifications_active_outlined;
      case NotificationPreference.floodOnly:
        return Icons.water_drop_outlined;
      case NotificationPreference.nearbyOnly:
        return Icons.near_me_outlined;
      case NotificationPreference.highRiskOnly:
        return Icons.priority_high_rounded;
    }
  }
}

class _RadiusChoiceChip extends StatelessWidget {
  const _RadiusChoiceChip({
    required this.radiusKm,
    required this.isSelected,
    required this.onTap,
  });

  final double radiusKm;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : RainGuardColors.primary,
        backgroundColor: isSelected ? RainGuardColors.primary : Colors.white,
        side: BorderSide(
          color: isSelected ? RainGuardColors.primary : RainGuardColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${radiusKm.toStringAsFixed(0)} km',
          maxLines: 1,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
