import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

class RainGuardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RainGuardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/images/rainguard-icon-transparent.png',
            width: 25,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text('RainGuard', style: RainGuardTextStyles.appBarTitle),
        ],
      ),
    );
  }
}
