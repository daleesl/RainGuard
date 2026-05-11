import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

class RainGuardCard extends StatelessWidget {
  const RainGuardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width = double.infinity,
    this.height,
    this.radius = 20,
    this.backgroundColor = Colors.white,
    this.borderColor = RainGuardColors.border,
    this.shadowColor = Colors.blueGrey,
    this.shadowOpacity = 0.07,
    this.blurRadius = 20,
    this.shadowOffset = const Offset(0, 10),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double shadowOpacity;
  final double blurRadius;
  final Offset shadowOffset;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(shadowOpacity),
            blurRadius: blurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}
