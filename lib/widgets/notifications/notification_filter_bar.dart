import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';

enum NotificationFilter { all, flood, rain }

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.floodCount,
    required this.rainCount,
    required this.onChanged,
  });

  final NotificationFilter selectedFilter;
  final int totalCount;
  final int floodCount;
  final int rainCount;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return RainGuardCard(
      padding: const EdgeInsets.all(8),
      radius: 18,
      shadowOpacity: 0.04,
      child: Row(
        children: [
          Expanded(
            child: _NotificationFilterChip(
              label: 'All',
              count: totalCount,
              icon: Icons.notifications_none_rounded,
              isSelected: selectedFilter == NotificationFilter.all,
              onTap: () => onChanged(NotificationFilter.all),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NotificationFilterChip(
              label: 'Flood',
              count: floodCount,
              icon: Icons.waves_rounded,
              isSelected: selectedFilter == NotificationFilter.flood,
              onTap: () => onChanged(NotificationFilter.flood),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NotificationFilterChip(
              label: 'Rain',
              count: rainCount,
              icon: Icons.thunderstorm_outlined,
              isSelected: selectedFilter == NotificationFilter.rain,
              onTap: () => onChanged(NotificationFilter.rain),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? RainGuardColors.primary
        : RainGuardColors.secondaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? RainGuardColors.softBlue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? RainGuardColors.primary.withOpacity(0.28)
                  : RainGuardColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$label ($count)',
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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
