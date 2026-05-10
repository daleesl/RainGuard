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
  // Tweak these if you want to adjust the onboarding rhythm later.
  static const _headerHeightBase = 380.0;
  static const _brandTopGapBase = 16.0;
  static const _heroTopBase = 126.0;
  static const _heroAspectRatio = 1.48;
  static const _heroWidthFactor = 0.84;
  static const _copyTopGapBase = 24.0;
  static const _buttonTopGapBase = 34.0;

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
            final scale = (width / 390).clamp(0.86, 1.0);
            final verticalScale = (height / 844).clamp(0.86, 1.0);
            final headerHeight = _headerHeightBase * verticalScale;
            final horizontalPadding = 28.0 * scale;
            final heroWidth = (width * _heroWidthFactor).clamp(328.0, 370.0);
            final heroHeight = heroWidth / _heroAspectRatio;

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
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        top: _brandTopGapBase * scale,
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
                    left: (width - heroWidth) / 2,
                    top: _heroTopBase * verticalScale,
                    child: Container(
                      width: heroWidth,
                      height: heroHeight,
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
                  Positioned.fill(
                    top: headerHeight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        _copyTopGapBase * verticalScale,
                        horizontalPadding,
                        24 * verticalScale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OnboardingCopy(scale: scale, availableWidth: width),
                          SizedBox(height: _buttonTopGapBase * verticalScale),
                          SizedBox(
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
                          SizedBox(height: 14 * verticalScale),
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
  const _OnboardingCopy({
    required this.scale,
    required this.availableWidth,
  });

  final double scale;
  final double availableWidth;

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
            fontSize: (availableWidth * 0.028).clamp(11.2, 12.5),
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
            fontSize: (availableWidth * 0.079).clamp(30.0, 33.5),
            fontWeight: FontWeight.w800,
            height: 1.16,
            letterSpacing: -0.35,
          ),
        ),
        SizedBox(height: 9 * scale),
        Text(
          'RainGuard combines weather, location, and community reports so every alert feels local and useful.',
          style: GoogleFonts.poppins(
            color: OnboardingScreen._muted,
            fontSize: (availableWidth * 0.035).clamp(13.2, 15.0),
            fontWeight: FontWeight.w400,
            height: 1.38,
          ),
        ),
        SizedBox(height: 17 * scale),
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
            Expanded(
              child: _FeatureChip(
                background: OnboardingScreen._reportChip,
                dot: OnboardingScreen._reportDot,
                textColor: const Color(0xFF0B355E),
                label: 'Photo reports',
                scale: scale,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.background,
    required this.dot,
    required this.textColor,
    required this.label,
    required this.scale,
    this.width,
  });

  final double? width;
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
