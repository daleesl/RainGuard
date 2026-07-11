import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/rainguard_theme.dart';
import '../../widgets/auth/auth_footer_link.dart';
import '../../widgets/auth/auth_password_toggle.dart';
import '../../widgets/rainguard_button.dart';
import '../../widgets/rainguard_text_field.dart';
import '../main_wrapper.dart';
import 'signup_screen.dart';

part 'login_screen_parts.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
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
            final metrics = _LoginMetrics.fromSize(
              width,
              height,
              MediaQuery.paddingOf(context).top,
            );

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
                      height: metrics.topBandHeight,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: primaryBlue),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: metrics.horizontalPadding - 2,
                          top: metrics.gap(6),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/rainguard-icon-transparent.png',
                              width: 39.3 * metrics.logoScale,
                              height: 50 * metrics.logoScale,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: metrics.space(12)),
                            Text(
                              'RainGuard',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: metrics.font(18),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.horizontalPadding,
                        metrics.contentTop,
                        metrics.horizontalPadding,
                        metrics.bottomPadding,
                      ),
                      child: Form(
                        key: _formKey,
                        child: _LoginFormContent(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isLoading: _isLoading,
                          obscurePassword: _obscurePassword,
                          metrics: metrics,
                          onLogin: _login,
                          onOpenSignup: _openSignup,
                          onTogglePassword: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
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
