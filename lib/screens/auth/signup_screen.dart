import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/rainguard_theme.dart';
import '../../widgets/rainguard_button.dart';
import '../../widgets/rainguard_text_field.dart';
import '../main_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const background = RainGuardColors.background;
  static const primaryBlue = RainGuardColors.primary;
  static const muted = RainGuardColors.muted;
  static const labelColor = Color(0xFF5C7488);
  static const placeholder = Color(0xFF7890A3);
  static const fieldBorder = RainGuardColors.signupFieldBorder;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.createAccountWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainWrapper()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email already has a RainGuard account.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please use a stronger password.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      default:
        return error.message ?? 'Account creation failed. Please try again.';
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainWrapper()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-up was cancelled or failed.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 390).clamp(0.86, 1.12);
            final verticalScale = (height / 844).clamp(0.86, 1.08);

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Stack(
                  children: [
                    Container(
                      width: width,
                      constraints: BoxConstraints(minHeight: height),
                      color: background,
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      height: 236 * verticalScale,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: primaryBlue),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        67 * verticalScale,
                        24 * scale,
                        28 * verticalScale,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create your\nRainGuard account',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 12 * verticalScale),
                            Text(
                              'Use email and password, or choose Google for\na faster sign-up.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFD9F2FF),
                                fontSize: 8 * scale,
                                fontWeight: FontWeight.w500,
                                height: 1.43,
                              ),
                            ),
                            SizedBox(height: 62 * verticalScale),
                            _SignupCard(
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              obscurePassword: _obscurePassword,
                              obscureConfirmPassword: _obscureConfirmPassword,
                              onTogglePassword: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              onToggleConfirmPassword: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                              scale: scale,
                              verticalScale: verticalScale,
                            ),
                            SizedBox(height: 24 * verticalScale),
                            RainGuardGoogleButton(
                              onPressed: _isGoogleLoading
                                  ? null
                                  : _continueWithGoogle,
                              scale: scale,
                              compact: true,
                              label: _isGoogleLoading ? 'Connecting...' : null,
                            ),
                            SizedBox(height: 19 * verticalScale),
                            RainGuardPrimaryButton(
                              label: 'Create account',
                              isLoading: _isLoading,
                              onPressed: _createAccount,
                              scale: scale,
                              height: 54 * scale,
                              fontSize: 12 * scale,
                            ),
                            SizedBox(height: 12 * verticalScale),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Already have an account? Log in',
                                  style: GoogleFonts.poppins(
                                    color: muted,
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.w600,
                                    height: 1.38,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({
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
                color: _SignupScreenState.primaryBlue,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: 29 * verticalScale),
          RainGuardTextField(
            label: 'First name',
            hintText: 'John',
            controller: firstNameController,
            textCapitalization: TextCapitalization.words,
            labelPadding: const EdgeInsets.only(left: 12),
            labelColor: _SignupScreenState.labelColor,
            labelFontSize: 10,
            labelFontWeight: FontWeight.w700,
            labelHeight: 1.33,
            labelLetterSpacing: 0,
            labelGap: 8,
            fieldBorderColor: _SignupScreenState.fieldBorder,
            hintColor: _SignupScreenState.placeholder,
            inputFontSize: 12,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'First name is required.';
              }
              return null;
            },
          ),
          SizedBox(height: 19 * verticalScale),
          RainGuardTextField(
            label: 'Last name',
            hintText: 'Jester',
            controller: lastNameController,
            textCapitalization: TextCapitalization.words,
            labelPadding: const EdgeInsets.only(left: 12),
            labelColor: _SignupScreenState.labelColor,
            labelFontSize: 10,
            labelFontWeight: FontWeight.w700,
            labelHeight: 1.33,
            labelLetterSpacing: 0,
            labelGap: 8,
            fieldBorderColor: _SignupScreenState.fieldBorder,
            hintColor: _SignupScreenState.placeholder,
            inputFontSize: 12,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Last name is required.';
              }
              return null;
            },
          ),
          SizedBox(height: 19 * verticalScale),
          RainGuardTextField(
            label: 'Email address',
            hintText: 'yourname@gmail.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            suffix: const Icon(
              Icons.check_circle,
              color: Color(0xFF8EE3B5),
              size: 20,
            ),
            labelPadding: const EdgeInsets.only(left: 12),
            labelColor: _SignupScreenState.labelColor,
            labelFontSize: 10,
            labelFontWeight: FontWeight.w700,
            labelHeight: 1.33,
            labelLetterSpacing: 0,
            labelGap: 8,
            fieldBorderColor: _SignupScreenState.fieldBorder,
            hintColor: _SignupScreenState.placeholder,
            inputFontSize: 12,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required.';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email.';
              }
              return null;
            },
          ),
          SizedBox(height: 19 * verticalScale),
          RainGuardTextField(
            label: 'Password',
            hintText: 'At least 8 characters',
            controller: passwordController,
            obscureText: obscurePassword,
            suffix: TextButton(
              onPressed: onTogglePassword,
              child: Text(obscurePassword ? 'Show' : 'Hide'),
            ),
            labelPadding: const EdgeInsets.only(left: 12),
            labelColor: _SignupScreenState.labelColor,
            labelFontSize: 10,
            labelFontWeight: FontWeight.w700,
            labelHeight: 1.33,
            labelLetterSpacing: 0,
            labelGap: 8,
            fieldBorderColor: _SignupScreenState.fieldBorder,
            hintColor: _SignupScreenState.placeholder,
            inputFontSize: 12,
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
          RainGuardTextField(
            label: 'Confirm password',
            hintText: 'Re-enter password',
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            suffix: TextButton(
              onPressed: onToggleConfirmPassword,
              child: Text(obscureConfirmPassword ? 'Show' : 'Hide'),
            ),
            labelPadding: const EdgeInsets.only(left: 12),
            labelColor: _SignupScreenState.labelColor,
            labelFontSize: 10,
            labelFontWeight: FontWeight.w700,
            labelHeight: 1.33,
            labelLetterSpacing: 0,
            labelGap: 8,
            fieldBorderColor: _SignupScreenState.fieldBorder,
            hintColor: _SignupScreenState.placeholder,
            inputFontSize: 12,
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
                color: _SignupScreenState.muted,
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
