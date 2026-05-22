import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../widgets/common_widgets.dart';
import '../services/theme_service.dart';
import '../connection/api_service.dart';
import '../connection/pomiar_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  Lokalizacja? _lokalizacja;
  bool _isLoading = true;
  String _timeString = "--:--";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pobierzGps();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pobierzGps();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pobierzGps() async {
    try {
      final nowaLokalizacja = await _apiService.getOstatniaLokalizacja();
      if (mounted) {
        String parsedTime = "--:--";
        if (nowaLokalizacja.data.length >= 16) {
          parsedTime = nowaLokalizacja.data.substring(11, 16);
        }
        setState(() {
          _lokalizacja = nowaLokalizacja;
          _timeString = parsedTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Błąd pobierania pozycji GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().isHighContrast,
      builder: (context, isHighContrast, child) {
        return Scaffold(
          backgroundColor: isHighContrast
              ? Colors.black
              : const Color(0xFFF5F5F7),
          body: SafeArea(
            child: _isLoading || _lokalizacja == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            _lokalizacja!.lat,
                            _lokalizacja!.lon,
                          ),
                          initialZoom: 16.0,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: isHighContrast
                                ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _lokalizacja!.lat,
                                  _lokalizacja!.lon,
                                ),
                                width: 80,
                                height: 80,
                                child: UserLocationMarker(
                                  isHighContrast: isHighContrast,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isHighContrast ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isHighContrast
                                ? Border.all(color: Colors.yellow, width: 2)
                                : null,
                            boxShadow: [
                              if (!isHighContrast)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ostatnia aktualizacja: $_timeString',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isHighContrast
                                      ? Colors.yellow
                                      : const Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pozycja namierzona (na żywo)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast
                                      ? Colors.yellow
                                      : const Color(0xFF3F976E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 2),
        );
      },
    );
  }
}

class UserLocationMarker extends StatelessWidget {
  final bool isHighContrast;
  const UserLocationMarker({super.key, this.isHighContrast = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.yellow.withOpacity(0.3)
                : const Color(0xFF079287).withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.black : const Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighContrast ? Colors.yellow : Colors.white,
              width: 3,
            ),
          ),
          child: Icon(
            Icons.person,
            color: isHighContrast ? Colors.yellow : Colors.black87,
            size: 24,
          ),
        ),
        Positioned(
          bottom: 10,
          child: CustomPaint(
            size: const Size(10, 10),
            painter: TrianglePainter(
              color: isHighContrast ? Colors.yellow : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
