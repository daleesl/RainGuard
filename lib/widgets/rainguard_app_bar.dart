import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          SvgPicture.asset(
            'assets/images/rainGuard-Logo.svg',
            width: 25,
            height: 32,
          ),
          const SizedBox(width: 8),
          const Text('RainGuard', style: RainGuardTextStyles.appBarTitle),
        ],
      ),
    );
  }
}
