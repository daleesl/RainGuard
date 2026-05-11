import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/rainguard_theme.dart';

class RainGuardTextField extends StatelessWidget {
  const RainGuardTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.labelPadding = EdgeInsets.zero,
    this.labelColor = RainGuardColors.muted,
    this.labelFontSize = 10,
    this.labelFontWeight = FontWeight.w600,
    this.labelHeight = 1.36,
    this.labelLetterSpacing = 0.77,
    this.labelGap = 7,
    this.fieldBorderColor = RainGuardColors.authFieldBorder,
    this.focusedBorderColor = RainGuardColors.primary,
    this.hintColor = RainGuardColors.muted,
    this.inputFontSize = 12,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 18,
    ),
  });

  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final EdgeInsets labelPadding;
  final Color labelColor;
  final double labelFontSize;
  final FontWeight labelFontWeight;
  final double labelHeight;
  final double labelLetterSpacing;
  final double labelGap;
  final Color fieldBorderColor;
  final Color focusedBorderColor;
  final Color hintColor;
  final double inputFontSize;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: labelPadding,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: labelColor,
              fontSize: labelFontSize,
              fontWeight: labelFontWeight,
              height: labelHeight,
              letterSpacing: labelLetterSpacing,
            ),
          ),
        ),
        SizedBox(height: labelGap),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.poppins(
            color: RainGuardColors.ink,
            fontSize: inputFontSize,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: hintColor,
              fontSize: inputFontSize,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: suffix,
            contentPadding: contentPadding,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: fieldBorderColor, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: fieldBorderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
