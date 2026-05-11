import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RainGuardColors {
  const RainGuardColors._();

  static const background = Color(0xFFF4FAFD);
  static const primary = Color(0xFF1778D4);
  static const primaryDark = Color(0xFF0B355E);
  static const ink = Color(0xFF102033);
  static const deepInk = Color(0xFF0A1422);
  static const muted = Color(0xFF667B8F);
  static const secondaryText = Color(0xFF697B8C);
  static const sectionLabel = Color(0xFF526B82);
  static const border = Color(0xFFD9E7EF);
  static const authFieldBorder = Color(0xFFD8E8F2);
  static const signupFieldBorder = Color(0xFFCFE5F2);
  static const softBlue = Color(0xFFE7F4FF);
  static const softGreen = Color(0xFFE6F8F1);
  static const success = Color(0xFF28C59D);
  static const warningFill = Color(0xFFFFF5DC);
  static const warningText = Color(0xFFB26B00);
  static const homeIndicator = Color(0xFFB8C8D4);
  static const splashBackground = Color(0xFF08243F);
  static const splashTopCircle = Color(0xFF124F7D);
  static const splashCircleAccent = Color(0xFF149BEE);
  static const splashBottomCircle = Color(0xFF165D70);
}

class RainGuardRadii {
  const RainGuardRadii._();

  static const small = 8.0;
  static const medium = 14.0;
  static const large = 18.0;
  static const card = 20.0;
  static const sheet = 28.0;
  static const pill = 99.0;
}

class RainGuardShadows {
  const RainGuardShadows._();

  static List<BoxShadow> card({double opacity = 0.07}) {
    return [
      BoxShadow(
        color: Colors.blueGrey.withOpacity(opacity),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static const hero = [
    BoxShadow(color: Color(0x29082138), blurRadius: 22, offset: Offset(0, 12)),
  ];
}

class RainGuardTextStyles {
  const RainGuardTextStyles._();

  static const appBarTitle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 14,
  );

  static const pageTitle = TextStyle(
    color: RainGuardColors.ink,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static const sectionTitle = TextStyle(
    color: RainGuardColors.ink,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );

  static const cardTitle = TextStyle(
    color: RainGuardColors.ink,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const body = TextStyle(
    color: RainGuardColors.secondaryText,
    fontSize: 8,
    height: 1.35,
  );

  static const label = TextStyle(
    color: RainGuardColors.sectionLabel,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
  );
}

class RainGuardTheme {
  const RainGuardTheme._();

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: RainGuardColors.primary),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: RainGuardColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: RainGuardColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: RainGuardTextStyles.appBarTitle,
      ),
    );
  }
}
