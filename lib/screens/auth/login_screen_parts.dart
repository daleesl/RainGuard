part of 'login_screen.dart';

class _LoginFormContent extends StatelessWidget {
  const _LoginFormContent({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.metrics,
    required this.onLogin,
    required this.onOpenSignup,
    required this.onTogglePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final _LoginMetrics metrics;
  final VoidCallback onLogin;
  final VoidCallback onOpenSignup;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: GoogleFonts.poppins(
            color: _LoginScreenState.ink,
            fontSize: metrics.font(20),
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
        SizedBox(height: metrics.gap(10)),
        Text(
          'Check your area, report conditions, and keep your community informed.',
          style: GoogleFonts.poppins(
            color: _LoginScreenState.muted,
            fontSize: metrics.font(8),
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        SizedBox(height: metrics.gap(34)),
        RainGuardTextField(
          label: 'EMAIL',
          controller: emailController,
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
          controller: passwordController,
          obscureText: obscurePassword,
          labelFontSize: metrics.font(10),
          inputFontSize: metrics.font(12),
          labelGap: metrics.gap(7),
          contentPadding: metrics.fieldPadding,
          suffix: AuthPasswordToggle(
            obscureText: obscurePassword,
            onPressed: onTogglePassword,
            color: _LoginScreenState.primaryBlue,
            fontSize: metrics.font(10),
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
                color: _LoginScreenState.primaryBlue,
                fontSize: metrics.font(10),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: metrics.gap(13)),
        RainGuardPrimaryButton(
          label: 'Log in to RainGuard',
          isLoading: isLoading,
          onPressed: onLogin,
          scale: metrics.controlScale,
          height: metrics.buttonHeight,
          fontSize: metrics.font(12),
          radius: metrics.radius(18),
        ),
        SizedBox(height: metrics.gap(25)),
        Center(
          child: AuthFooterLink(
            label: 'New here? Create an account',
            onPressed: onOpenSignup,
            color: _LoginScreenState.muted,
            fontSize: metrics.font(10),
          ),
        ),
      ],
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
    final typeScale = (widthScale * (height < 760 ? 0.96 : 1))
        .clamp(0.82, 1.08)
        .toDouble();
    final controlScale = ((widthScale + heightScale) / 2)
        .clamp(0.82, 1.08)
        .toDouble();

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
