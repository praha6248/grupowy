import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/common_widgets.dart';
import 'heart_history_screen.dart';
import '../services/theme_service.dart';
import '../connection/pomiar_model.dart';
import '../connection/api_service.dart'; 

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  late Future<Pomiar> _ostatniPomiarFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _ostatniPomiarFuture = _apiService.getOstatniPomiar();
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
                  title: 'Pomiar tętna',
                  showChartIcon: true,
                  onHistoryTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HeartHistoryScreen(),
                      ),
                    );
                  },
                ),

                Expanded(
                  child: FutureBuilder<Pomiar>(
                    future: _ostatniPomiarFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: isHighContrast
                                ? Colors.yellow
                                : Colors.redAccent,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Błąd pobierania danych:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isHighContrast
                                  ? Colors.yellow
                                  : Colors.red,
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return const Center(
                          child: Text('Brak danych o tętnie.'),
                        );
                      }

                      final Pomiar ostatniPomiar = snapshot.data!;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            HeartIndicator(isHighContrast: isHighContrast),
                            const SizedBox(height: 20),

                            ResultValue(
                              isHighContrast: isHighContrast,
                              tetno: ostatniPomiar.tetno,
                            ),

                            const SizedBox(height: 30),

                            StatusCard(
                              isHighContrast: isHighContrast,
                              tetno: ostatniPomiar.tetno,
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 1),
        );
      },
    );
  }
}

class HeartIndicator extends StatelessWidget {
  final bool isHighContrast;
  const HeartIndicator({super.key, required this.isHighContrast});

  @override
  Widget build(BuildContext context) {
    if (isHighContrast) {
      return SizedBox(
        width: 170,
        height: 170,
        child: Center(
          child: SvgPicture.asset(
            'assets/serce.svg',
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
        color: Color(0xFFF7BABF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFFF28C95),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(22.0),
          child: SvgPicture.asset(
            'assets/serce.svg',
            colorFilter: const ColorFilter.mode(
              Color(0xFFEB4755),
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
  final int tetno;

  const ResultValue({
    super.key,
    required this.isHighContrast,
    required this.tetno,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isHighContrast ? Colors.yellow : const Color(0xFF2D2D2D);
    final subColor = isHighContrast ? Colors.yellow : const Color(0xFF555555);

    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: tetno.toString(), // Wyświetlanie dynamicznego tętna
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                  color: mainColor,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: ' BPM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: subColor,
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
              color: isHighContrast ? Colors.yellow : const Color(0xFFEB4755),
            ),
            const SizedBox(width: 4),
            Text(
              'Ostatni pomiar',
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
  final int tetno;

  const StatusCard({
    super.key,
    required this.isHighContrast,
    required this.tetno,
  });

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA WIDEŁEK (TĘTNO) ---
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (tetno < 60) {
      statusText = 'obniżone';
      statusColor = isHighContrast ? Colors.yellow : Colors.blue;
      statusIcon = Icons.arrow_downward_rounded;
    } else if (tetno > 100) {
      statusText = 'podwyższone';
      statusColor = isHighContrast
          ? Colors.yellow
          : const Color(0xFFEB4755); // Czerwony alert
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = 'w normie';
      statusColor = isHighContrast ? Colors.yellow : Colors.green;
      statusIcon = Icons.favorite;
    }
    // -----------------------------

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast
            ? Border.all(color: Colors.yellow, width: 2)
            : null,
        boxShadow: isHighContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'twoje tętno jest',
            style: TextStyle(
              color: isHighContrast ? Colors.yellow : Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                statusText, // Wyświetlamy dynamiczny tekst
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isHighContrast
                      ? Colors.yellow
                      : statusColor, // Dynamiczny kolor
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                statusIcon,
                color: statusColor,
                size: 22,
              ), // Dynamiczna ikona
            ],
          ),

          const SizedBox(height: 15),

          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '60-100',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: isHighContrast
                          ? Colors.yellow
                          : const Color(0xFF2D2D2D),
                    ),
                  ),
                  TextSpan(
                    text: ' BPM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isHighContrast
                          ? Colors.yellow
                          : const Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          CustomBarGauge(
            isHighContrast: isHighContrast,
            activeColor: statusColor, // Pasek też zmieni kolor!
            tetno: tetno,
          ),
        ],
      ),
    );
  }
}

class CustomBarGauge extends StatelessWidget {
  final bool isHighContrast;
  final Color activeColor;
  final int tetno;

  const CustomBarGauge({
    super.key,
    required this.isHighContrast,
    required this.activeColor,
    required this.tetno,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isHighContrast ? Colors.yellow : activeColor;
    final bgColor = isHighContrast
        ? Colors.grey.shade900
        : const Color(0xFFE0E0E0);
    final dottedColor = isHighContrast ? Colors.black : Colors.white;
    final sideTextColor = isHighContrast ? Colors.yellow : Colors.grey;

    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: bgColor,
                  border: isHighContrast
                      ? Border.all(color: Colors.yellow)
                      : null,
                ),
              ),
              Align(
                alignment: const Alignment(0.0, 0.0),
                child: Container(
                  height: 24,
                  width: 100,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(1, 24),
                      painter: DottedLinePainter(color: dottedColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('20', style: TextStyle(color: sideTextColor, fontSize: 12)),
            Text(
              "$tetno\nOstatni pomiar", // Wyświetlanie dynamicznego tętna na pasku
              textAlign: TextAlign.center,
              style: TextStyle(color: barColor, fontSize: 10),
            ),
            Text('140', style: TextStyle(color: sideTextColor, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + 3), paint);
      startY += 5;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
