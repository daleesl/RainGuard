import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import 'home_section_header.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onMapTap,
    required this.onReportTap,
    required this.onVerifyTap,
    required this.onHotlinesTap,
  });

  final VoidCallback onMapTap;
  final VoidCallback onReportTap;
  final VoidCallback onVerifyTap;
  final VoidCallback onHotlinesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader('Quick Actions'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.map_outlined,
                  label: 'Map',
                  subtitle: 'View flood areas',
                  color: RainGuardColors.primary,
                  onTap: onMapTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.add_location_alt_outlined,
                  label: 'Report',
                  subtitle: 'File a report',
                  color: Colors.red.shade600,
                  onTap: onReportTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.verified_user_outlined,
                  label: 'Verify',
                  subtitle: 'Unlock reporting',
                  color: Colors.green.shade700,
                  onTap: onVerifyTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.local_phone_outlined,
                  label: 'Hotlines',
                  subtitle: 'Emergency help',
                  color: Colors.amber.shade800,
                  onTap: onHotlinesTap,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RainGuardColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 11),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
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
        ),
      ),
    );
  }
}
