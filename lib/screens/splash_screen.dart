import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/login_screen.dart';
import 'auth/onboarding_screen.dart';
import 'main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _background = Color(0xFF08243F);
  static const _topCircleFill = Color(0xFF124F7D);
  static const _circleAccent = Color(0xFF149BEE);
  static const _bottomCircleFill = Color(0xFF165D70);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      unawaited(_goToApp());
    });
  }

  Future<void> _goToApp() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(OnboardingScreen.seenPreferenceKey) ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;
    final nextScreen = currentUser != null
        ? const MainWrapper()
        : hasSeenOnboarding
            ? const LoginScreen()
            : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final widthScale = (width / 390).clamp(0.82, 1.16);
            final heightScale = (height / 844).clamp(0.78, 1.0);
            final scale = widthScale < heightScale ? widthScale : heightScale;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplashBackgroundPainter(
                      topCircleFill: _topCircleFill,
                      circleAccent: _circleAccent,
                      bottomCircleFill: _bottomCircleFill,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 34 * scale),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: width - (68 * scale),
                          height:
                              height -
                              MediaQuery.paddingOf(context).top -
                              MediaQuery.paddingOf(context).bottom,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/rainGuard-Logo.svg',
                                width: 118 * scale,
                                height: 148 * scale,
                              ),
                              SizedBox(height: 24 * scale),
                              Text(
                                'RainGuard',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 37 * scale,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter({
    required this.topCircleFill,
    required this.circleAccent,
    required this.bottomCircleFill,
  });

  final Color topCircleFill;
  final Color circleAccent;
  final Color bottomCircleFill;

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..color = topCircleFill
      ..style = PaintingStyle.fill;
    final topStroke = Paint()
      ..color = circleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final bottomPaint = Paint()
      ..color = bottomCircleFill
      ..style = PaintingStyle.fill;

    final topRadius = size.width * 0.38;
    final topCenter = Offset(-size.width * 0.02, size.height * 0.065);
    canvas.drawCircle(topCenter, topRadius, topPaint);
    canvas.drawCircle(topCenter, topRadius, topStroke);

    final bottomRadius = size.width * 0.53;
    final bottomCenter = Offset(size.width * 1.02, size.height * 0.97);
    canvas.drawCircle(bottomCenter, bottomRadius, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.topCircleFill != topCircleFill ||
        oldDelegate.circleAccent != circleAccent ||
        oldDelegate.bottomCircleFill != bottomCircleFill;
  }
}
