import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';

enum NotificationFilter {
  all,
  official,
  community,
  pending,
  verified,
  resolved,
}

class NotificationFilterOption {
  const NotificationFilterOption({
    required this.filter,
    required this.icon,
    required this.label,
    this.count,
  });

  final NotificationFilter filter;
  final IconData icon;
  final String label;
  final int? count;
}

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.selectedFilter,
    required this.options,
    required this.onChanged,
  });

  final NotificationFilter selectedFilter;
  final List<NotificationFilterOption> options;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return RainGuardCard(
      padding: const EdgeInsets.all(8),
      radius: 18,
      shadowOpacity: 0.04,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (options.length <= 3) {
            return Row(
              children: [
                for (final option in options) ...[
                  Expanded(child: _buildChip(option)),
                  if (option != options.last) const SizedBox(width: 8),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in options) ...[
                  _buildChip(option),
                  if (option != options.last) const SizedBox(width: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(NotificationFilterOption option) {
    return _NotificationFilterChip(
      label: option.label,
      count: option.count,
      icon: option.icon,
      isSelected: selectedFilter == option.filter,
      onTap: () => onChanged(option.filter),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.label,
    this.count,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int? count;
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
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? RainGuardColors.softBlue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? RainGuardColors.primary.withValues(alpha: 0.28)
                  : RainGuardColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                count == null ? label : '$label ($count)',
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
