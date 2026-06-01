import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

class RainGuardSectionHeader extends StatelessWidget {
  const RainGuardSectionHeader({super.key, required this.title, this.count});

  final int? count;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: RainGuardColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count != null)
          Text(
            count.toString(),
            style: const TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}
