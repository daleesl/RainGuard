import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

class RainGuardLoadingState extends StatelessWidget {
  const RainGuardLoadingState({
    super.key,
    this.message = 'Loading RainGuard data...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            color: RainGuardColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
