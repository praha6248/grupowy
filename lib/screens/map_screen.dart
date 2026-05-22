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
  late Future<Lokalizacja> _lokalizacjaFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _lokalizacjaFuture = _apiService.getOstatniaLokalizacja();
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
            child: FutureBuilder<Lokalizacja>(
              future: _lokalizacjaFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Błąd GPS: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('Brak lokalizacji'));
                }

                final LatLng centerLocation = LatLng(
                  snapshot.data!.lat,
                  snapshot.data!.lon,
                );

                return Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: centerLocation,
                        initialZoom: 16.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                              point: centerLocation,
                              width: 80,
                              height: 80,
                              rotate: false,
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
                              'Ostatnia aktualizacja: ${snapshot.data!.data.substring(11, 16)}', // Wyciąga godzinę z daty ISO
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
                              'Pozycja namierzona',
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
                );
              },
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
                : const Color(0xFF5079287).withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.black : const Color(0xFFffffff),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighContrast ? Colors.yellow : Colors.white,
              width: 3,
            ),
            boxShadow: [
              if (!isHighContrast)
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
            ],
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
