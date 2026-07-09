import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: RainGuardColors.ink,
      ),
    );
  }
}
