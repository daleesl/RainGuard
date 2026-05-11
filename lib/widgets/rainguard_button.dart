import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/rainguard_theme.dart';

class RainGuardPrimaryButton extends StatelessWidget {
  const RainGuardPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.scale = 1,
    this.height,
    this.fontSize,
    this.radius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double scale;
  final double? height;
  final double? fontSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 56 * scale,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: RainGuardColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: RainGuardColors.primary.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius ?? 18 * scale),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: fontSize ?? 12 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                ),
              ),
      ),
    );
  }
}

class RainGuardGoogleButton extends StatelessWidget {
  const RainGuardGoogleButton({
    super.key,
    required this.onPressed,
    this.scale = 1,
    this.compact = false,
    this.label,
  });

  final VoidCallback? onPressed;
  final double scale;
  final bool compact;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 294 * scale : double.infinity;
    final height = compact ? 44 * scale : 56 * scale;
    final radius = (compact ? 16 : 18) * scale;
    final textColor = compact
        ? RainGuardColors.primaryDark
        : RainGuardColors.ink;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: compact ? RainGuardColors.background : Colors.white,
          foregroundColor: textColor,
          side: const BorderSide(color: RainGuardColors.authFieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: GoogleFonts.poppins(
                color: RainGuardColors.primary,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: compact ? 19 * scale : 13 * scale),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label ??
                      (compact
                          ? 'Or continue with Google'
                          : 'Continue with Google'),
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
