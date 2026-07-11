import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.obscureText,
    required this.onPressed,
    this.color,
    this.fontSize,
  });

  final bool obscureText;
  final VoidCallback onPressed;
  final Color? color;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final text = obscureText ? 'Show' : 'Hide';
    final style = color == null && fontSize == null
        ? null
        : GoogleFonts.poppins(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          );

    return TextButton(
      onPressed: onPressed,
      child: Text(text, style: style),
    );
  }
}
