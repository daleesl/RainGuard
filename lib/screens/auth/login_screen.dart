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

  Widget _googleButton(_LoginMetrics metrics) {
    if (_isGoogleLoading) {
      return RainGuardGoogleButton(
        onPressed: null,
        scale: metrics.controlScale,
        height: metrics.buttonHeight,
        fontSize: metrics.font(12),
        radius: metrics.radius(18),
        label: 'Connecting...',
      );
    }

    return RainGuardGoogleButton(
      onPressed: _continueWithGoogle,
      scale: metrics.controlScale,
      height: metrics.buttonHeight,
      fontSize: metrics.font(12),
      radius: metrics.radius(18),
    );
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
                            SvgPicture.asset(
                              'assets/images/rainGuard-Logo.svg',
                              width: 39.3 * metrics.logoScale,
                              height: 50 * metrics.logoScale,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: GoogleFonts.poppins(
                                color: ink,
                                fontSize: metrics.font(20),
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            SizedBox(height: metrics.gap(10)),
                            Text(
                              'Check your area, report conditions, and keep your community informed.',
                              style: GoogleFonts.poppins(
                                color: muted,
                                fontSize: metrics.font(8),
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: metrics.gap(34)),
                            RainGuardTextField(
                              label: 'EMAIL',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              labelFontSize: metrics.font(10),
                              inputFontSize: metrics.font(12),
                              labelGap: metrics.gap(7),
                              contentPadding: metrics.fieldPadding,
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
                            SizedBox(height: metrics.gap(20)),
                            RainGuardTextField(
                              label: 'PASSWORD',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              labelFontSize: metrics.font(10),
                              inputFontSize: metrics.font(12),
                              labelGap: metrics.gap(7),
                              contentPadding: metrics.fieldPadding,
                              suffix: TextButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                child: Text(
                                  _obscurePassword ? 'Show' : 'Hide',
                                  style: GoogleFonts.poppins(
                                    color: primaryBlue,
                                    fontSize: metrics.font(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                    fontSize: metrics.font(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: metrics.gap(13)),
                            RainGuardPrimaryButton(
                              label: 'Log in to RainGuard',
                              isLoading: _isLoading,
                              onPressed: _login,
                              scale: metrics.controlScale,
                              height: metrics.buttonHeight,
                              fontSize: metrics.font(12),
                              radius: metrics.radius(18),
                            ),
                            SizedBox(height: metrics.gap(31)),
                            _DividerWithText(metrics: metrics),
                            SizedBox(height: metrics.gap(29)),
                            _googleButton(metrics),
                            SizedBox(height: metrics.gap(25)),
                            Center(
                              child: TextButton(
                                onPressed: _openSignup,
                                child: Text(
                                  'New here? Create an account',
                                  style: GoogleFonts.poppins(
                                    color: muted,
                                    fontSize: metrics.font(10),
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

class _LoginMetrics {
  const _LoginMetrics({
    required this.widthScale,
    required this.heightScale,
    required this.typeScale,
    required this.controlScale,
    required this.topInset,
  });

  factory _LoginMetrics.fromSize(double width, double height, double topInset) {
    final widthScale = (width / 390).clamp(0.86, 1.12).toDouble();
    final heightScale = (height / 844).clamp(0.72, 1.08).toDouble();
    final typeScale = (widthScale * (height < 760 ? 0.96 : 1)).clamp(
      0.82,
      1.08,
    ).toDouble();
    final controlScale = ((widthScale + heightScale) / 2).clamp(
      0.82,
      1.08,
    ).toDouble();

    return _LoginMetrics(
      widthScale: widthScale,
      heightScale: heightScale,
      typeScale: typeScale,
      controlScale: controlScale,
      topInset: topInset,
    );
  }

  final double widthScale;
  final double heightScale;
  final double typeScale;
  final double controlScale;
  final double topInset;

  double font(double value) =>
      (value * typeScale).clamp(value * 0.88, value * 1.08).toDouble();
  double gap(double value) => value * heightScale;
  double space(double value) => value * widthScale;
  double radius(double value) => value * controlScale;

  double get horizontalPadding => space(30).clamp(24, 34).toDouble();
  double get logoHeight => 50 * logoScale;
  double get topBandHeight {
    final fittedHeader = topInset + gap(6) + logoHeight + gap(12);
    final scaledHeader = gap(101).clamp(78, 116).toDouble();
    return fittedHeader > scaledHeader ? fittedHeader : scaledHeader;
  }

  double get contentTop {
    final scaledTop = gap(130).clamp(96, 140).toDouble();
    final fittedTop = topBandHeight + gap(26);
    return fittedTop > scaledTop ? fittedTop : scaledTop;
  }

  double get bottomPadding => gap(22).clamp(16, 26).toDouble();
  double get logoScale => controlScale;
  double get buttonHeight => (56 * controlScale).clamp(48, 58).toDouble();
  EdgeInsets get fieldPadding => EdgeInsets.symmetric(
        horizontal: space(20).clamp(16, 22).toDouble(),
        vertical: gap(18).clamp(13, 19).toDouble(),
      );
}

class _DividerWithText extends StatelessWidget {
  const _DividerWithText({required this.metrics});

  final _LoginMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _LoginScreenState.fieldBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.space(34)),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              color: _LoginScreenState.muted,
              fontSize: metrics.font(8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _LoginScreenState.fieldBorder)),
      ],
    );
  }
}
