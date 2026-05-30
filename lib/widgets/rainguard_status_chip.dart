import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

enum RainGuardStatusTone { info, success, warning, danger }

class RainGuardStatusChip extends StatelessWidget {
  const RainGuardStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = RainGuardStatusTone.info,
  });

  final String label;
  final IconData? icon;
  final RainGuardStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _chipColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(RainGuardRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.text),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusChipColors _chipColors(RainGuardStatusTone tone) {
    switch (tone) {
      case RainGuardStatusTone.success:
        return const _StatusChipColors(
          fill: RainGuardColors.softGreen,
          text: RainGuardColors.success,
        );
      case RainGuardStatusTone.warning:
        return const _StatusChipColors(
          fill: RainGuardColors.warningFill,
          text: RainGuardColors.warningText,
        );
      case RainGuardStatusTone.danger:
        return _StatusChipColors(
          fill: Colors.red.shade50,
          text: Colors.red.shade700,
        );
      case RainGuardStatusTone.info:
        return const _StatusChipColors(
          fill: RainGuardColors.softBlue,
          text: RainGuardColors.primary,
        );
    }
  }
}

class _StatusChipColors {
  const _StatusChipColors({required this.fill, required this.text});

  final Color fill;
  final Color text;
}
