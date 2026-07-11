import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/rainguard_theme.dart';
import '../rainguard_text_field.dart';
import 'auth_password_toggle.dart';

class SignupFormCard extends StatelessWidget {
  const SignupFormCard({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.scale,
    required this.verticalScale,
  });

  static const _primaryBlue = RainGuardColors.primary;
  static const _muted = RainGuardColors.muted;
  static const _labelColor = Color(0xFF5C7488);
  static const _placeholder = Color(0xFF7890A3);
  static const _fieldBorder = RainGuardColors.signupFieldBorder;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final double scale;
  final double verticalScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18 * scale,
        20 * verticalScale,
        18 * scale,
        12 * verticalScale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30 * scale),
        border: Border.all(color: const Color(0xFFD6ECF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F082E4D),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2 * scale),
            child: Text(
              'EMAIL SIGN UP',
              style: GoogleFonts.poppins(
                color: _primaryBlue,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: 29 * verticalScale),
          _NameField(
            label: 'First name',
            hintText: 'John',
            controller: firstNameController,
            emptyMessage: 'First name is required.',
          ),
          SizedBox(height: 19 * verticalScale),
          _NameField(
            label: 'Last name',
            hintText: 'Doe',
            controller: lastNameController,
            emptyMessage: 'Last name is required.',
          ),
          SizedBox(height: 19 * verticalScale),
          _EmailField(controller: emailController),
          SizedBox(height: 19 * verticalScale),
          _PasswordField(
            label: 'Password',
            hintText: 'At least 8 characters',
            controller: passwordController,
            obscureText: obscurePassword,
            onToggle: onTogglePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required.';
              }
              if (value.length < 8) {
                return 'Use at least 8 characters.';
              }
              return null;
            },
          ),
          SizedBox(height: 19 * verticalScale),
          _PasswordField(
            label: 'Confirm password',
            hintText: 'Re-enter password',
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            onToggle: onToggleConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password.';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          SizedBox(height: 10 * verticalScale),
          Padding(
            padding: EdgeInsets.only(left: 20 * scale),
            child: Text(
              'Use 8+ characters. Avoid using your name or\nemail.',
              style: GoogleFonts.poppins(
                color: _muted,
                fontSize: 8 * scale,
                fontWeight: FontWeight.w400,
                height: 1.39,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.emptyMessage,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SignupTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return emptyMessage;
        }
        return null;
      },
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final isGmail = value.text.trim().toLowerCase().endsWith('@gmail.com');

        return _SignupTextField(
          label: 'Email address',
          hintText: 'john.doe@gmail.com',
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          suffix: isGmail
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF8EE3B5),
                  size: 20,
                )
              : null,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required.';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email.';
            }
            return null;
          },
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return _SignupTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      obscureText: obscureText,
      suffix: AuthPasswordToggle(obscureText: obscureText, onPressed: onToggle),
      validator: validator,
    );
  }
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return RainGuardTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      obscureText: obscureText,
      suffix: suffix,
      labelPadding: const EdgeInsets.only(left: 12),
      labelColor: SignupFormCard._labelColor,
      labelFontSize: 10,
      labelFontWeight: FontWeight.w700,
      labelHeight: 1.33,
      labelLetterSpacing: 0,
      labelGap: 8,
      fieldBorderColor: SignupFormCard._fieldBorder,
      hintColor: SignupFormCard._placeholder,
      inputFontSize: 12,
      validator: validator,
    );
  }
}
