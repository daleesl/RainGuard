import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/rainguard_theme.dart';
import '../../widgets/rainguard_button.dart';
import '../../widgets/rainguard_text_field.dart';
import '../main_wrapper.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const background = RainGuardColors.background;
  static const primaryBlue = RainGuardColors.primary;
  static const ink = RainGuardColors.ink;
  static const muted = RainGuardColors.muted;
  static const fieldBorder = RainGuardColors.authFieldBorder;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      default:
        return error.message ?? 'Login failed. Please try again.';
    }
  }

  void _openSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignupScreen()));
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
          content: Text('Google sign-in was cancelled or failed.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _googleButton(double scale) {
    if (_isGoogleLoading) {
      return RainGuardGoogleButton(
        onPressed: null,
        scale: scale,
        label: 'Connecting...',
      );
    }

    return RainGuardGoogleButton(onPressed: _continueWithGoogle, scale: scale);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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
                      height: 101 * verticalScale,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: primaryBlue),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 28 * scale,
                          top: 6 * scale,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/rainGuard-Logo.svg',
                              width: 39.3 * scale,
                              height: 50 * scale,
                            ),
                            SizedBox(width: 12 * scale),
                            Text(
                              'RainGuard',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        30 * scale,
                        130 * verticalScale,
                        30 * scale,
                        22 * verticalScale,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: GoogleFonts.poppins(
                                color: ink,
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                                letterSpacing: -0.34,
                              ),
                            ),
                            SizedBox(height: 10 * verticalScale),
                            Text(
                              'Check your area, report conditions, and\nkeep your community informed.',
                              style: GoogleFonts.poppins(
                                color: muted,
                                fontSize: 8 * scale,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 34 * verticalScale),
                            RainGuardTextField(
                              label: 'EMAIL',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
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
                            SizedBox(height: 20 * verticalScale),
                            RainGuardTextField(
                              label: 'PASSWORD',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffix: TextButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                child: Text(_obscurePassword ? 'Show' : 'Hide'),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.poppins(
                                    color: primaryBlue,
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 13 * verticalScale),
                            RainGuardPrimaryButton(
                              label: 'Log in to RainGuard',
                              isLoading: _isLoading,
                              onPressed: _login,
                              scale: scale,
                            ),
                            SizedBox(height: 31 * verticalScale),
                            DividerWithText(scale: scale),
                            SizedBox(height: 29 * verticalScale),
                            _googleButton(scale),
                            SizedBox(height: 25 * verticalScale),
                            Center(
                              child: TextButton(
                                onPressed: _openSignup,
                                child: Text(
                                  'New here? Create an account',
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

class DividerWithText extends StatelessWidget {
  const DividerWithText({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _LoginScreenState.fieldBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 34 * scale),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              color: _LoginScreenState.muted,
              fontSize: 8 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _LoginScreenState.fieldBorder)),
      ],
    );
  }
}
