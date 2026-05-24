import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../connection/pomiar_model.dart';
import '../connection/api_service.dart';

class BloodSaturationHistoryScreen extends StatefulWidget {
  const BloodSaturationHistoryScreen({super.key});

  @override
  State<BloodSaturationHistoryScreen> createState() =>
      _BloodSaturationHistoryScreenState();
}

class _BloodSaturationHistoryScreenState
    extends State<BloodSaturationHistoryScreen> {
  late Future<List<Pomiar>> _historiaFuture;
  final ApiService _apiService = ApiService();

  final List<String> days = ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'];

  final Color mainBlue = const Color(0xFF4B93D1);
  final Color lightBlue = const Color(0xFFCDE4F7);

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
        final Color mainColor = isHighContrast ? Colors.yellow : mainBlue;
        final Color textColor = isHighContrast
            ? Colors.yellow
            : const Color(0xFF2D2D2D);
        final Color subTextColor = isHighContrast ? Colors.yellow : Colors.grey;

        return Scaffold(
          backgroundColor: isHighContrast
              ? Colors.black
              : const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Column(
              children: [
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
                        ' Nasycenie SpO2',
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
                      }

                      final data = snapshot.data!.reversed.toList();
                      final List<double> values = data
                          .map((p) => p.saturacja)
                          .toList();
                      final double avg =
                          values.reduce((a, b) => a + b) / values.length;

                      final List<FlSpot> spots = List.generate(data.length, (
                        i,
                      ) {
                        return FlSpot(i.toDouble(), data[i].saturacja);
                      });

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
                              'Średnia saturacja:',
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
                                  '%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.opacity, color: mainColor, size: 30),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Expanded(
                              child: LineChart(
                                _buildChartData(
                                  spots,
                                  mainColor,
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
    Color color,
    bool isHighContrast,
    Color subTextColor,
  ) {
    return LineChartData(
      gridData: FlGridData(show: true, horizontalInterval: 5),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (v, m) => Text(
              '${v.toInt()}%',
              style: TextStyle(color: subTextColor, fontSize: 10),
            ),
          ),
        ),
      ),
      minY: 70,
      maxY: 100, // Zakres dla saturacji
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 4,
          isCurved: false,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }
}
