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
            width: 30,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text('RainGuard', style: RainGuardTextStyles.appBarTitle),
        ],
      ),
    );
  }
}
