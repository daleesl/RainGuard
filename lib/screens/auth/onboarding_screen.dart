import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/rainguard_theme.dart';
import '../../widgets/rainguard_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _background = RainGuardColors.background;
  static const _primaryBlue = RainGuardColors.primary;
  static const _ink = RainGuardColors.ink;
  static const _muted = RainGuardColors.muted;
  static const _mapChip = RainGuardColors.softBlue;
  static const _reportChip = RainGuardColors.softGreen;
  static const _reportDot = RainGuardColors.success;

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
            final horizontalPadding = 28.0 * scale;
            final maxHeroWidth = math.max(0.0, width - horizontalPadding * 2);
            final heroWidth = math.min(
              (width * _heroWidthFactor).clamp(300.0, 370.0),
              maxHeroWidth,
            );
            final heroHeight = heroWidth / _heroAspectRatio;
            final headerHeight = math.max(
              _headerHeightBase * verticalScale,
              _heroTopBase * verticalScale + heroHeight + 28 * verticalScale,
            );
            final bottomSafeSpace = MediaQuery.paddingOf(context).bottom + 12;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Container(
                  width: width,
                  color: _background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(
                              child: DecoratedBox(
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
                            Positioned(
                              left: (width - heroWidth) / 2,
                              top: _heroTopBase * verticalScale,
                              child: Container(
                                width: heroWidth,
                                height: heroHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    24 * scale,
                                  ),
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
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _copyTopGapBase * verticalScale,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OnboardingCopy(
                              scale: scale,
                              availableWidth: width,
                            ),
                            SizedBox(height: _buttonTopGapBase * verticalScale),
                            RainGuardPrimaryButton(
                              label: 'Get started',
                              onPressed: () => _goToLogin(context),
                              scale: scale,
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
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w600,
                                  height: 1.38,
                                ),
                              ),
                              child: const Text('I already have an account'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: bottomSafeSpace),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.scale, required this.availableWidth});

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
            fontSize: 10 * scale,
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
            fontSize: 20 * scale,
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
            fontSize: 8 * scale,
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
              fontSize: 10 * scale,
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
