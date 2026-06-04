import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_risk_assessment.dart';
import '../models/user_profile.dart';
import '../services/home_risk_service.dart';
import '../services/user_profile_service.dart';
import '../services/weather_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/location_constants.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_card.dart';

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
      builder: (context) => const _HotlinesSheet(),
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
                return _Header(
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
                    _WeatherRiskCard(
                      isLoading: _isLoadingWeather,
                      temp: _weatherTemp,
                      description: _weatherDesc,
                      riskAssessment: _riskAssessment,
                      isLoadingRisk: _isLoadingRisk,
                      riskLoadFailed: _riskLoadFailed,
                    ),
                    const SizedBox(height: 14),
                    _SafetyActionCard(
                      riskAssessment: _riskAssessment,
                      isLoadingRisk: _isLoadingRisk,
                      riskLoadFailed: _riskLoadFailed,
                    ),
                    const SizedBox(height: 18),
                    _QuickActions(
                      onMapTap: () => widget.onNavigate(1),
                      onReportTap: () => widget.onNavigate(1),
                      onVerifyTap: () => widget.onNavigate(3),
                      onHotlinesTap: _showHotlines,
                    ),
                    const SizedBox(height: 18),
                    const _PreparednessTips(),
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

class _Header extends StatelessWidget {
  const _Header({required this.displayName, required this.locationName});

  final String displayName;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 58),
      decoration: BoxDecoration(
        color: RainGuardColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $displayName!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherRiskCard extends StatelessWidget {
  const _WeatherRiskCard({
    required this.isLoading,
    required this.temp,
    required this.description,
    required this.riskAssessment,
    required this.isLoadingRisk,
    required this.riskLoadFailed,
  });

  final bool isLoading;
  final String temp;
  final String description;
  final HomeRiskAssessment? riskAssessment;
  final bool isLoadingRisk;
  final bool riskLoadFailed;

  @override
  Widget build(BuildContext context) {
    final riskLevel = riskAssessment?.level;
    final hasActiveRisk = riskAssessment?.hasActiveRisk ?? false;
    final riskColor = riskLoadFailed
        ? Colors.red.shade700
        : switch (riskLevel) {
            HomeFloodRiskLevel.high => Colors.red.shade700,
            HomeFloodRiskLevel.watch => Colors.amber.shade800,
            HomeFloodRiskLevel.clear => Colors.green.shade700,
            null => RainGuardColors.primary,
          };
    final riskStatus = switch ((isLoadingRisk, riskLoadFailed, riskLevel)) {
      (true, _, _) => 'Checking current risk',
      (_, true, _) => 'Risk status unavailable',
      (_, _, HomeFloodRiskLevel.high) => 'Active flood risk',
      (_, _, HomeFloodRiskLevel.watch) => 'Flood watch',
      _ => 'Clear',
    };
    final riskDetail = switch ((isLoadingRisk, riskLoadFailed)) {
      (true, _) => 'Reviewing recent reports and official alerts',
      (_, true) => 'Pull to refresh current safety information',
      _ => riskAssessment?.reason ?? 'No current risk information',
    };
    final updateLabel = riskAssessment == null
        ? null
        : '${riskAssessment!.lastSourceUpdateAt == null ? 'Checked' : 'Updated'} '
              '${TimeOfDay.fromDateTime(riskAssessment!.lastUpdatedAt).format(context)}';

    return RainGuardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isLoading ? '-- \u00B0C' : temp,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: RainGuardColors.deepInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: RainGuardColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: RainGuardColors.softBlue,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Icon(
                    riskLevel == HomeFloodRiskLevel.high
                        ? Icons.thunderstorm_rounded
                        : riskLevel == HomeFloodRiskLevel.watch
                        ? Icons.water_drop_outlined
                        : Icons.wb_sunny_rounded,
                    size: 38,
                    color: hasActiveRisk
                        ? Colors.amber.shade700
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flood Risk Assessment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: RainGuardColors.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        riskStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: hasActiveRisk || riskLoadFailed
                              ? riskColor
                              : RainGuardColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riskDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainGuardColors.sectionLabel,
                          height: 1.3,
                          fontSize: 8,
                        ),
                      ),
                      if (updateLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          updateLabel,
                          style: const TextStyle(
                            color: RainGuardColors.muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 86,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        riskLevel == HomeFloodRiskLevel.high
                            ? Icons.warning_amber_rounded
                            : riskLevel == HomeFloodRiskLevel.watch
                            ? Icons.visibility_outlined
                            : Icons.shield_outlined,
                        color: riskColor,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoadingRisk
                            ? '...'
                            : riskLoadFailed
                            ? 'N/A'
                            : riskAssessment?.levelLabel ?? 'N/A',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyActionCard extends StatelessWidget {
  const _SafetyActionCard({
    required this.riskAssessment,
    required this.isLoadingRisk,
    required this.riskLoadFailed,
  });

  final HomeRiskAssessment? riskAssessment;
  final bool isLoadingRisk;
  final bool riskLoadFailed;

  @override
  Widget build(BuildContext context) {
    final level = riskAssessment?.level;
    final color = riskLoadFailed
        ? Colors.red.shade700
        : switch (level) {
            HomeFloodRiskLevel.high => Colors.red.shade700,
            HomeFloodRiskLevel.watch => Colors.amber.shade800,
            HomeFloodRiskLevel.clear => Colors.green.shade700,
            null => RainGuardColors.primary,
          };
    final title = switch ((isLoadingRisk, riskLoadFailed, level)) {
      (true, _, _) => 'Checking current flood risk',
      (_, true, _) => 'Current risk information unavailable',
      (_, _, HomeFloodRiskLevel.high) => 'High risk: Avoid low-lying roads',
      (_, _, HomeFloodRiskLevel.watch) => 'Flood watch: Stay alert',
      _ => 'Clear: Stay updated',
    };
    final message = switch ((isLoadingRisk, riskLoadFailed, level)) {
      (true, _, _) => 'Reviewing recent reports and official advisories.',
      (_, true, _) => 'Pull down to retry before making safety decisions.',
      (_, _, HomeFloodRiskLevel.high) =>
        'Check the map before travelling and keep emergency items ready.',
      (_, _, HomeFloodRiskLevel.watch) =>
        'Monitor official advisories and avoid flood-prone routes.',
      _ => 'Monitor alerts and keep your safety essentials within reach.',
    };

    return RainGuardCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              level == HomeFloodRiskLevel.high
                  ? Icons.alt_route_rounded
                  : level == HomeFloodRiskLevel.watch
                  ? Icons.visibility_outlined
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMapTap,
    required this.onReportTap,
    required this.onVerifyTap,
    required this.onHotlinesTap,
  });

  final VoidCallback onMapTap;
  final VoidCallback onReportTap;
  final VoidCallback onVerifyTap;
  final VoidCallback onHotlinesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Quick Actions'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.map_outlined,
                  label: 'Map',
                  subtitle: 'View flood areas',
                  color: RainGuardColors.primary,
                  onTap: onMapTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.add_location_alt_outlined,
                  label: 'Report',
                  subtitle: 'File a report',
                  color: Colors.red.shade600,
                  onTap: onReportTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.verified_user_outlined,
                  label: 'Verify',
                  subtitle: 'Unlock reporting',
                  color: Colors.green.shade700,
                  onTap: onVerifyTap,
                ),
                _QuickActionTile(
                  width: itemWidth,
                  icon: Icons.local_phone_outlined,
                  label: 'Hotlines',
                  subtitle: 'Emergency help',
                  color: Colors.amber.shade800,
                  onTap: onHotlinesTap,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RainGuardColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 11),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparednessTips extends StatelessWidget {
  const _PreparednessTips();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('Preparedness Tips'),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.battery_charging_full_rounded,
          title: 'Charge your phone',
          body: 'Keep your phone and power bank ready before heavy rain.',
        ),
        SizedBox(height: 10),
        _TipCard(
          icon: Icons.folder_copy_outlined,
          title: 'Prepare documents',
          body: 'Place IDs and important papers in a waterproof pouch.',
        ),
        SizedBox(height: 10),
        _TipCard(
          icon: Icons.waves_rounded,
          title: 'Avoid floodwater',
          body: 'Do not walk or drive through moving floodwater.',
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return RainGuardCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RainGuardColors.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: RainGuardColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotlinesSheet extends StatelessWidget {
  const _HotlinesSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: RainGuardColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Emergency Hotlines',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _HotlineRow(label: 'National Emergency', number: '911'),
          const _HotlineRow(
            label: 'Barangay / Local DRRMO',
            number: 'Add local number',
          ),
          const _HotlineRow(
            label: 'Rescue / Medical Help',
            number: 'Add local number',
          ),
        ],
      ),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  const _HotlineRow({required this.label, required this.number});

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RainGuardColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.local_phone_outlined, color: RainGuardColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    number,
                    style: const TextStyle(
                      color: RainGuardColors.secondaryText,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: RainGuardColors.ink,
      ),
    );
  }
}
