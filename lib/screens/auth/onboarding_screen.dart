import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _background = Color(0xFFF4FAFD);
  static const _primaryBlue = Color(0xFF1778D4);
  static const _ink = Color(0xFF102033);
  static const _muted = Color(0xFF667B8F);
  static const _mapChip = Color(0xFFE7F4FF);
  static const _reportChip = Color(0xFFE6F8F1);
  static const _reportDot = Color(0xFF28C59D);
  static const _homeIndicator = Color(0xFFB8C8D4);

  static const seenPreferenceKey = 'has_seen_onboarding';

  Future<void> _goToLogin(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenPreferenceKey, true);
    if (!context.mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 390).clamp(0.86, 1.12);
            final verticalScale = (height / 844).clamp(0.86, 1.08);
            final headerHeight = 384.0 * verticalScale;

            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(32 * scale),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: headerHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: _primaryBlue),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(left: 28 * scale, top: 21 * scale),
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
                              fontSize: 25 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 33 * scale,
                    top: 119 * verticalScale,
                    child: Container(
                      width: 324 * scale,
                      height: 231 * verticalScale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24 * scale),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x29082138),
                            blurRadius: 22,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/onboarding_hero-pic.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28 * scale,
                    right: 28 * scale,
                    top: headerHeight + (23 * verticalScale),
                    child: _OnboardingCopy(scale: scale),
                  ),
                  Positioned(
                    left: 28 * scale,
                    right: 28 * scale,
                    bottom: 57 * verticalScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56 * scale,
                          child: ElevatedButton(
                            onPressed: () => _goToLogin(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              shadowColor: const Color(0x29082138),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18 * scale),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.33,
                              ),
                            ),
                            child: const Text('Get started'),
                          ),
                        ),
                        SizedBox(height: 13 * verticalScale),
                        TextButton(
                          onPressed: () => _goToLogin(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _muted,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale,
                              vertical: 8 * verticalScale,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                          child: const Text('I already have an account'),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: (width - (134 * scale)) / 2,
                    bottom: 27 * verticalScale,
                    child: Container(
                      width: 134 * scale,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _homeIndicator,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'STAY AHEAD OF FLOODS',
          style: GoogleFonts.poppins(
            color: OnboardingScreen._primaryBlue,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: 0.84,
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          'Know which\nstreets to avoid\nbefore you leave.',
          style: GoogleFonts.poppins(
            color: OnboardingScreen._ink,
            fontSize: 35 * scale,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.35,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          'RainGuard combines weather, location, and\ncommunity reports so every alert feels local\nand useful.',
          style: GoogleFonts.poppins(
            color: OnboardingScreen._muted,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        SizedBox(height: 21 * scale),
        Row(
          children: [
            _FeatureChip(
              width: 144 * scale,
              background: OnboardingScreen._mapChip,
              dot: OnboardingScreen._primaryBlue,
              textColor: OnboardingScreen._primaryBlue,
              label: 'Map alerts',
              scale: scale,
            ),
            SizedBox(width: 12 * scale),
            _FeatureChip(
              width: 178 * scale,
              background: OnboardingScreen._reportChip,
              dot: OnboardingScreen._reportDot,
              textColor: const Color(0xFF0B355E),
              label: 'Photo reports',
              scale: scale,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.width,
    required this.background,
    required this.dot,
    required this.textColor,
    required this.label,
    required this.scale,
  });

  final double width;
  final Color background;
  final Color dot;
  final Color textColor;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34 * scale,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6 * scale,
            height: 6 * scale,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: 16 * scale),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              height: 1.33,
              letterSpacing: 0.12,
            ),
          ),
        ],
      ),
    );
  }
}
