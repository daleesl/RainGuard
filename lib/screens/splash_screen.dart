import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const _mutedText = Color(0xFFB9DCEB);
  static const _pillFill = Color(0xFF155B85);
  static const _pillDot = Color(0xFF58D6E8);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _goToApp);
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainWrapper()),
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
                        children: [
                          const Spacer(flex: 34),
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
                          SizedBox(height: 26 * scale),
                          Text(
                            'Flood alerts before water\nreaches your street.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFD8F2FF),
                              fontSize: 17 * scale,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 54 * scale),
                          _InfoPill(scale: scale),
                          SizedBox(height: 20 * scale),
                          Text(
                            'Built for community rainfall, flood risk, and\nemergency readiness.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: _mutedText,
                              fontSize: 11.5 * scale,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                          ),
                          const Spacer(flex: 19),
                          Container(
                            width: 124 * scale,
                            height: 4.5,
                            margin: EdgeInsets.only(bottom: 18 * scale),
                            decoration: BoxDecoration(
                              color: const Color(0xA3FFFFFF),
                              borderRadius: BorderRadius.circular(999),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31 * scale,
      padding: EdgeInsets.symmetric(horizontal: 15 * scale),
      decoration: BoxDecoration(
        color: _SplashScreenState._pillFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5 * scale,
            height: 5.5 * scale,
            decoration: const BoxDecoration(
              color: _SplashScreenState._pillDot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 21 * scale),
          Text(
            'Live rain + verified reports',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11.5 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
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
