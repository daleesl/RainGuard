import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_risk_assessment.dart';
import '../models/user_profile.dart';
import '../services/home_risk_service.dart';
import '../services/user_profile_service.dart';
import '../services/weather_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/location_constants.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_hotlines_sheet.dart';
import '../widgets/home/home_preparedness_tips.dart';
import '../widgets/home/home_quick_actions.dart';
import '../widgets/home/home_safety_action_card.dart';
import '../widgets/home/home_weather_risk_card.dart';
import '../widgets/rainguard_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Duration _riskRefreshInterval = Duration(minutes: 5);

  Timer? _riskRefreshTimer;
  String _weatherTemp = '-- \u00B0C';
  String _weatherDesc = 'Loading...';
  String _locationName = RainGuardCoverage.linggaLabel;
  bool _isLoadingWeather = true;
  bool _isLoadingRisk = true;
  bool _riskLoadFailed = false;
  HomeRiskAssessment? _riskAssessment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchWeatherData();
    _fetchRiskAssessment();
    _riskRefreshTimer = Timer.periodic(_riskRefreshInterval, (_) {
      unawaited(_fetchRiskAssessment());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_fetchRiskAssessment());
    }
  }

  @override
  void dispose() {
    _riskRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchRiskAssessment() async {
    if (mounted && _riskAssessment == null) {
      setState(() {
        _isLoadingRisk = true;
        _riskLoadFailed = false;
      });
    }

    try {
      final assessment = await HomeRiskService.loadCurrentAssessment();
      if (!mounted) return;
      setState(() {
        _riskAssessment = assessment;
        _isLoadingRisk = false;
        _riskLoadFailed = false;
      });
    } catch (error) {
      debugPrint('Home risk assessment error: $error');
      if (!mounted) return;
      setState(() {
        _isLoadingRisk = false;
        _riskLoadFailed = true;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      final weatherData = await WeatherService.getWeather(
        RainGuardCoverage.linggaLatitude,
        RainGuardCoverage.linggaLongitude,
      );

      if (!mounted) return;
      setState(() {
        _weatherTemp = '${weatherData['temp'].round()} \u00B0C';
        _weatherDesc = weatherData['description'];
        _locationName = RainGuardCoverage.linggaLabel;
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint('Weather API error: $e');
      if (!mounted) return;
      setState(() {
        _weatherTemp = 'N/A';
        _weatherDesc = 'Unavailable';
        _locationName = RainGuardCoverage.linggaLabel;
        _isLoadingWeather = false;
      });
    }
  }

  void _showHotlines() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const HomeHotlinesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchWeatherData(), _fetchRiskAssessment()]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            StreamBuilder<UserProfile?>(
              stream: UserProfileService.currentUserProfileStream(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return HomeHeader(
                  displayName: profile?.firstNameOrDisplay ?? 'RainGuard user',
                  locationName: _locationName,
                );
              },
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeWeatherRiskCard(
                      isLoading: _isLoadingWeather,
                      temp: _weatherTemp,
                      description: _weatherDesc,
                      riskAssessment: _riskAssessment,
                      isLoadingRisk: _isLoadingRisk,
                      riskLoadFailed: _riskLoadFailed,
                    ),
                    const SizedBox(height: 14),
                    HomeSafetyActionCard(
                      riskAssessment: _riskAssessment,
                      isLoadingRisk: _isLoadingRisk,
                      riskLoadFailed: _riskLoadFailed,
                    ),
                    const SizedBox(height: 18),
                    HomeQuickActions(
                      onMapTap: () => widget.onNavigate(1),
                      onReportTap: () => widget.onNavigate(1),
                      onVerifyTap: () => widget.onNavigate(3),
                      onHotlinesTap: _showHotlines,
                    ),
                    const SizedBox(height: 18),
                    const HomePreparednessTips(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
