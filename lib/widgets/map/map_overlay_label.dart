import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';

class MapOverlayLabel extends StatelessWidget {
  const MapOverlayLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.86),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: RainGuardColors.primary.withOpacity(0.22),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RainGuardColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
