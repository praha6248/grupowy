import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../connection/pomiar_model.dart';
import '../connection/api_service.dart';

class HeartHistoryScreen extends StatefulWidget {
  const HeartHistoryScreen({super.key});

  @override
  State<HeartHistoryScreen> createState() => _HeartHistoryScreenState();
}

class _HeartHistoryScreenState extends State<HeartHistoryScreen> {
  late Future<List<Pomiar>> _historiaFuture;
  final ApiService _apiService = ApiService();

  final List<String> days = ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'];
  int touchedIndex = -1;

  final Color mainPink = const Color(0xFFFF3344);
  final Color lightPink = const Color(0xFFFFB2B9);

  @override
  void initState() {
    super.initState();
    _historiaFuture = _apiService.getHistoriaPomiarow(limit: 7);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().isHighContrast,
      builder: (context, isHighContrast, child) {
        final Color mainColor = isHighContrast ? Colors.yellow : mainPink;
        final Color secColor = isHighContrast ? Colors.yellow : lightPink;
        final Color bgColor = isHighContrast
            ? Colors.black
            : const Color(0xFFF5F5F7);
        final Color textColor = isHighContrast
            ? Colors.yellow
            : const Color(0xFF2D2D2D);
        final Color subTextColor = isHighContrast ? Colors.yellow : Colors.grey;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Pasek nawigacji
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: isHighContrast
                              ? Colors.yellow
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        ' Tętno (Historia)',
                        style: TextStyle(
                          fontSize: 18,
                          color: isHighContrast
                              ? Colors.yellow
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<Pomiar>>(
                    future: _historiaFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Błąd: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Brak danych w bazie.'),
                        );
                      }

                      final data = snapshot.data!;
                      final displayData = data.reversed.toList();

                      final List<int> values = displayData
                          .map((p) => p.tetno)
                          .toList();
                      final double avg =
                          values.reduce((a, b) => a + b) / values.length;
                      final int minBpm = values.reduce(min);
                      final int maxBpm = values.reduce(max);

                      final List<FlSpot> spots = List.generate(
                        displayData.length,
                        (i) {
                          return FlSpot(
                            i.toDouble(),
                            displayData[i].tetno.toDouble(),
                          );
                        },
                      );

                      return Container(
                        margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
                              'Średnia z ostatnich pomiarów:',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${avg.toInt()}',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BPM',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Min: $minBpm | Max: $maxBpm',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Expanded(
                              child: LineChart(
                                _buildChartData(
                                  spots,
                                  mainColor,
                                  secColor,
                                  isHighContrast,
                                  subTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartData _buildChartData(
    List<FlSpot> spots,
    Color mainColor,
    Color secColor,
    bool isHighContrast,
    Color subTextColor,
  ) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}',
              style: TextStyle(color: subTextColor, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              days[value.toInt() % 7],
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: 40,
      maxY: 140,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: mainColor,
          barWidth: 4,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: !isHighContrast,
            color: mainColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
