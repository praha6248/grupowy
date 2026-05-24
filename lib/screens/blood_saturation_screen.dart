import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/common_widgets.dart';
import 'blood_saturation_history_screen.dart';
import '../services/theme_service.dart';
import '../connection/pomiar_model.dart';
import '../connection/api_service.dart';

class BloodSaturationScreen extends StatefulWidget {
  const BloodSaturationScreen({super.key});

  @override
  State<BloodSaturationScreen> createState() => _BloodSaturationScreenState();
}

class _BloodSaturationScreenState extends State<BloodSaturationScreen> {
  final ApiService _apiService = ApiService();
  Pomiar? _ostatniPomiar;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pobierzDane();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pobierzDane();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pobierzDane() async {
    try {
      final pomiar = await _apiService.getOstatniPomiar();
      if (mounted) {
        setState(() {
          _ostatniPomiar = pomiar;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _ostatniPomiar == null) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().isHighContrast,
      builder: (context, isHighContrast, child) {
        final bgColor = isHighContrast ? Colors.black : const Color(0xFFF4F1F2);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                HeaderSection(
                  title: 'Nasycenie krwi',
                  showChartIcon: true,
                  onHistoryTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BloodSaturationHistoryScreen(),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: isHighContrast
                                ? Colors.yellow
                                : const Color(0xFF4B93D1),
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Text(
                            'Błąd pobierania danych z Tora.\nSpróbuj ponownie później.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isHighContrast
                                  ? Colors.yellow
                                  : Colors.red,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              SaturationIndicator(
                                isHighContrast: isHighContrast,
                              ),
                              const SizedBox(height: 20),
                              ResultValue(
                                isHighContrast: isHighContrast,
                                saturacja: _ostatniPomiar?.saturacja ?? 95.0,
                              ),
                              const SizedBox(height: 30),
                              StatusCard(
                                isHighContrast: isHighContrast,
                                saturacja: _ostatniPomiar?.saturacja ?? 95.0,
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 0),
        );
      },
    );
  }
}

class SaturationIndicator extends StatelessWidget {
  final bool isHighContrast;
  const SaturationIndicator({super.key, required this.isHighContrast});

  @override
  Widget build(BuildContext context) {
    if (isHighContrast) {
      return SizedBox(
        width: 170,
        height: 170,
        child: Center(
          child: SvgPicture.asset(
            'assets/sat.svg',
            width: 140,
            colorFilter: const ColorFilter.mode(Colors.yellow, BlendMode.srcIn),
          ),
        ),
      );
    }
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFCDE4F7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF8BC0E9),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(22.0),
          child: SvgPicture.asset(
            'assets/sat.svg',
            colorFilter: const ColorFilter.mode(
              Color(0xFF4B93D1),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class ResultValue extends StatelessWidget {
  final bool isHighContrast;
  final double saturacja;
  const ResultValue({
    super.key,
    required this.isHighContrast,
    required this.saturacja,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isHighContrast ? Colors.yellow : const Color(0xFF2D2D2D);
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${saturacja.toInt()}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                  color: mainColor,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: ' %',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: isHighContrast ? Colors.yellow : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: isHighContrast ? Colors.yellow : const Color(0xFF4B93D1),
            ),
            const SizedBox(width: 4),
            Text(
              'Ostatni pomiar (na żywo)',
              style: TextStyle(
                color: isHighContrast ? Colors.yellow : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatusCard extends StatelessWidget {
  final bool isHighContrast;
  final double saturacja;
  const StatusCard({
    super.key,
    required this.isHighContrast,
    required this.saturacja,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (saturacja < 90) {
      statusText = 'krytycznie niskie';
      statusColor = const Color(0xFFEB4755);
      statusIcon = Icons.warning_amber_rounded;
    } else if (saturacja < 95) {
      statusText = 'obniżone';
      statusColor = Colors.orange;
      statusIcon = Icons.arrow_downward_rounded;
    } else {
      statusText = 'w normie';
      statusColor = Colors.green;
      statusIcon = Icons.opacity;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast
            ? Border.all(color: Colors.yellow, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'twoje nasycenie krwi jest',
            style: TextStyle(
              color: isHighContrast ? Colors.yellow : Colors.grey,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isHighContrast ? Colors.yellow : statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                statusIcon,
                color: isHighContrast ? Colors.yellow : statusColor,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              '95-100 %',
              style: TextStyle(
                fontSize: 20,
                color: isHighContrast ? Colors.yellow : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CustomSpO2BarGauge(
            isHighContrast: isHighContrast,
            activeColor: statusColor,
            saturacja: saturacja,
          ),
        ],
      ),
    );
  }
}

class _CustomSpO2BarGauge extends StatelessWidget {
  final bool isHighContrast;
  final Color activeColor;
  final double saturacja;
  const _CustomSpO2BarGauge({
    required this.isHighContrast,
    required this.activeColor,
    required this.saturacja,
  });

  @override
  Widget build(BuildContext context) {
    double alignmentValue = ((saturacja - 70) / (100 - 70) * 2) - 1;
    alignmentValue = alignmentValue.clamp(-1.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isHighContrast
                    ? Colors.grey.shade900
                    : const Color(0xFFE0E0E0),
              ),
            ),
            Align(
              alignment: Alignment(alignmentValue, 0),
              child: Container(
                height: 24,
                width: 4,
                color: isHighContrast ? Colors.yellow : activeColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '70',
              style: TextStyle(
                color: isHighContrast ? Colors.yellow : Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              '${saturacja.toInt()}%',
              style: TextStyle(
                color: isHighContrast ? Colors.yellow : activeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '100',
              style: TextStyle(
                color: isHighContrast ? Colors.yellow : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
