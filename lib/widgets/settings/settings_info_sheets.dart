import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import 'settings_tiles.dart';

class ThemeInfoSheet extends StatelessWidget {
  const ThemeInfoSheet({super.key});

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
            'Theme',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RainGuard is currently using the light theme. Dark theme can be added later as a separate app-wide pass.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 9,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RainGuardColors.primary),
            ),
            child: const Row(
              children: [
                SettingsTileIcon(icon: Icons.light_mode_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Light theme active',
                    style: TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: RainGuardColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BarangayLocationSheet extends StatelessWidget {
  const BarangayLocationSheet({super.key});

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
            'Default Barangay Location',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RainGuard is focused on Barangay Quiling, Talisay for this capstone. Weather summaries and default map context use this area, while submitted reports still use the user\'s actual GPS when available.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 9,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RainGuardColors.border),
            ),
            child: const Row(
              children: [
                SettingsTileIcon(icon: Icons.place_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Barangay Quiling, Talisay',
                    style: TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
