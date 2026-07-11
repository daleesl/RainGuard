import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/rainguard_theme.dart';
import '../../widgets/auth/auth_footer_link.dart';
import '../../widgets/auth/signup_form_card.dart';
import '../../widgets/rainguard_button.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
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
                              'Create your account with email and password to\nkeep your community informed.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFD9F2FF),
                                fontSize: 8 * scale,
                                fontWeight: FontWeight.w500,
                                height: 1.43,
                              ),
                            ),
                            SizedBox(height: 62 * verticalScale),
                            SignupFormCard(
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
                              child: AuthFooterLink(
                                label: 'Already have an account? Log in',
                                onPressed: () => Navigator.of(context).pop(),
                                color: muted,
                                fontSize: 10 * scale,
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
