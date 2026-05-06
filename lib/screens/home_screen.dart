import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _weatherTemp = '-- \u00B0C';
  String _weatherDesc = 'Loading...';
  String _locationName = 'Brgy. Lingga, Calamba';
  bool _isLoadingWeather = true;
  int _floodCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _fetchFloodActivityCount();
  }

  Future<void> _fetchFloodActivityCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('report_type', isEqualTo: 'flood')
          .get();
      if (!mounted) return;
      setState(() => _floodCount = snapshot.docs.length);
    } catch (e) {
      debugPrint('Flood count error: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    double lat = 14.2046;
    double lon = 121.1553;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          lat = position.latitude;
          lon = position.longitude;
        }
      }
    } catch (e) {
      debugPrint('Geolocator error, using fallback: $e');
    }

    try {
      final weatherData = await WeatherService.getWeather(lat, lon);
      final addressName = await GeocodingService.getAddressFromCoordinates(
        lat,
        lon,
      );

      if (!mounted) return;
      setState(() {
        _weatherTemp = '${weatherData['temp'].round()} \u00B0C';
        _weatherDesc = weatherData['description'];
        _locationName =
            (addressName != 'Location Error' && addressName != 'Unknown Location')
                ? addressName
                : weatherData['location'];
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint('Weather API error: $e');
      if (!mounted) return;
      setState(() {
        _weatherTemp = 'N/A';
        _weatherDesc = 'Unavailable';
        _locationName = 'Location Error';
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
    final hasActiveRisk = _floodCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent.shade400,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text(
              'RainGuard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchWeatherData(),
            _fetchFloodActivityCount(),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(locationName: _locationName),
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
                      floodCount: _floodCount,
                      hasActiveRisk: hasActiveRisk,
                    ),
                    const SizedBox(height: 14),
                    _SafetyActionCard(hasActiveRisk: hasActiveRisk),
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
  const _Header({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 58),
      decoration: BoxDecoration(
        color: Colors.blueAccent.shade400,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, John Jester!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
    required this.floodCount,
    required this.hasActiveRisk,
  });

  final bool isLoading;
  final String temp;
  final String description;
  final int floodCount;
  final bool hasActiveRisk;

  @override
  Widget build(BuildContext context) {
    final riskColor = hasActiveRisk ? Colors.red.shade700 : Colors.green.shade700;

    return _SurfaceCard(
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
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: Color(0xFF0A1422),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF102033),
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
                    color: const Color(0xFFE7F4FF),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Icon(
                    hasActiveRisk
                        ? Icons.thunderstorm_rounded
                        : Icons.wb_sunny_rounded,
                    size: 38,
                    color: hasActiveRisk ? Colors.amber.shade700 : Colors.orange,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102033),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        hasActiveRisk ? 'Active risk' : 'Clear',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: hasActiveRisk
                              ? Colors.red.shade700
                              : const Color(0xFF102033),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasActiveRisk
                            ? '$floodCount flood report(s) detected'
                            : 'No flood activity detected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF526B82),
                          height: 1.3,
                          fontSize: 13,
                        ),
                      ),
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
                        hasActiveRisk
                            ? Icons.warning_amber_rounded
                            : Icons.shield_outlined,
                        color: riskColor,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasActiveRisk ? 'High' : 'Green',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 15,
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
  const _SafetyActionCard({required this.hasActiveRisk});

  final bool hasActiveRisk;

  @override
  Widget build(BuildContext context) {
    final color = hasActiveRisk ? Colors.red.shade700 : Colors.green.shade700;

    return _SurfaceCard(
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
              hasActiveRisk
                  ? Icons.alt_route_rounded
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
                  hasActiveRisk
                      ? 'High risk: Avoid low-lying roads'
                      : 'Clear: Stay updated',
                  style: const TextStyle(
                    color: Color(0xFF102033),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasActiveRisk
                      ? 'Check the map before travelling and keep emergency items ready.'
                      : 'Monitor alerts and keep your safety essentials within reach.',
                  style: const TextStyle(
                    color: Color(0xFF697B8C),
                    fontSize: 12,
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
                  color: Colors.blueAccent.shade400,
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
              border: Border.all(color: const Color(0xFFD9E7EF)),
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
                    color: Color(0xFF102033),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF697B8C),
                    fontSize: 12,
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
  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102033),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF697B8C),
                    fontSize: 12,
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
        color: Color(0xFFF4FAFD),
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
              color: Color(0xFF102033),
              fontSize: 22,
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
          border: Border.all(color: const Color(0xFFD9E7EF)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_phone_outlined, color: Colors.blueAccent.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF102033),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Color(0xFF697B8C),
                      fontSize: 12,
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
        fontSize: 18,
        color: Color(0xFF102033),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
