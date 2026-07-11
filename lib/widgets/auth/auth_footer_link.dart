import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.fontSize,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.38,
        ),
      ),
    );
  }
}
