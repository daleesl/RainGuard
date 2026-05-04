import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _weatherTemp = '-- °C';
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
          .where('report_type', isEqualTo: 'flood') // adjust condition based on your model ('risk_level' or 'type')
          .get();
      setState(() {
        _floodCount = snapshot.docs.length;
      });
    } catch (_) {}
  }

  Future<void> _fetchWeatherData() async {
    //  fallback coordinates (Calamba, Laguna) 
    double lat = 14.2046;
    double lon = 121.1553;

    try {
      // 1. Properly handle Location Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Using fallback location.');
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          // 2. Fetch Native Real-time Coordinates seamlessly
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          lat = position.latitude;
          lon = position.longitude;
        } else {
          debugPrint('Location permissions denied. Using fallback location.');
        }
      }
    } catch (e) {
      debugPrint("Geolocator Error (Using Fallback): $e");
    }

    try {
      // 3. Fetch weather from OpenWeather via Service Cache
      final weatherData = await WeatherService.getWeather(lat, lon);
      
      // 4. Fetch precise barangay name via free Nominatim Cache
      final addressName = await GeocodingService.getAddressFromCoordinates(lat, lon);
      
      setState(() {
        _weatherTemp = '${weatherData['temp'].round()} °C';
        _weatherDesc = weatherData['description'];
        
        // If Nominatim fails entirely, fallback to OpenWeather's city label
        _locationName = (addressName != 'Location Error' && addressName != 'Unknown Location') 
            ? addressName 
            : weatherData['location']; 
            
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint("Weather API Error: $e"); // Print the actual error for debugging
      setState(() {
        _weatherTemp = 'N/A';
        _weatherDesc = 'Unavailable';
        _locationName = 'Location Error';
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent.shade400,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'RainGuard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Header
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade400,
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, John Jester!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // Overlapping Card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Column(
                  children: [
                    // Weather Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoadingWeather ? '-- °C' : _weatherTemp,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _weatherDesc,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.cloud_queue, size: 80, color: Colors.blue.shade400),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Risk Assessment Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Flood Risk Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _floodCount > 0 ? 'Active Risks' : 'Clear',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _floodCount > 0 ? Colors.red : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _floodCount > 0 ? '$_floodCount flood report(s)\ndetected' : 'No flood activity\ndetected',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Fake Gauge Chart
                          Column(
                            children: [
                              Icon(_floodCount > 0 ? Icons.warning_amber_rounded : Icons.speed, size: 70, color: _floodCount > 0 ? Colors.red : Colors.green.shade600),
                              Text(
                                _floodCount > 0 ? 'High' : 'Green',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _floodCount > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Community Initiatives
            Transform.translate(
              offset: const Offset(0, -10),
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Community Initiatives',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Reports >',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildInitiativeCard(Icons.group, 'Community Relief'),
                        const SizedBox(width: 12),
                        _buildInitiativeCard(Icons.support, 'Rescue Ops'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiativeCard(IconData iconData, String defaultTitle) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Center(
            child: Icon(iconData, size: 50, color: Colors.grey.shade400),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                defaultTitle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}