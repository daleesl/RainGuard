import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';

class MapFilterPill<T> extends StatelessWidget {
  const MapFilterPill({
    super.key,
    required this.filter,
    required this.isActive,
    required this.label,
    required this.onChanged,
  });

  final T filter;
  final bool isActive;
  final String label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: InkWell(
        onTap: () => onChanged(filter),
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? RainGuardColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : RainGuardColors.secondaryText,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
