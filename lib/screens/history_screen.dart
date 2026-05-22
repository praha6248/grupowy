import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/theme_service.dart';
import '../connection/api_service.dart';
import '../connection/pomiar_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Zdarzenie>> _zdarzeniaFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _zdarzeniaFuture = _apiService.getZdarzenia(
      limit: 20,
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().isHighContrast,
      builder: (context, isHighContrast, child) {
        return Scaffold(
          backgroundColor: isHighContrast
              ? Colors.black
              : const Color(0xFFF4F1F2),
          body: SafeArea(
            child: Column(
              children: [
                HeaderSection(
                  title: 'Aktywność i Zdarzenia',
                  showChartIcon: false,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Zdarzenie>>(
                    future: _zdarzeniaFuture,
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
                          child: Text('Brak zarejestrowanych zdarzeń.'),
                        );
                      }

                      final zdarzenia = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 24.0,
                          right: 24.0,
                          bottom: 120.0,
                        ),
                        itemCount: zdarzenia.length,
                        itemBuilder: (context, index) {
                          final event = zdarzenia[index];

                          DateTime dt =
                              DateTime.tryParse(event.data) ?? DateTime.now();
                          String timeStr =
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}  (${dt.day}.${dt.month})';

                          // Ustalmy, czy zdarzenie jest alertem (np. upadek)
                          bool isAlert =
                              event.typ_zdarzenia.toLowerCase().contains(
                                'upadek',
                              ) ||
                              event.typ_zdarzenia.toLowerCase().contains(
                                'krytyczne',
                              );

                          return _buildTimelineItem(
                            time: timeStr,
                            title: event.typ_zdarzenia,
                            isAlert: isAlert,
                            isHighContrast: isHighContrast,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 4),
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required bool isAlert,
    required bool isHighContrast,
  }) {
    final alertColor = const Color(0xFFEB4755);
    final infoColor = const Color(0xFF148FB8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isHighContrast ? Colors.yellow : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isHighContrast
                        ? Border.all(color: Colors.yellow, width: 1)
                        : null,
                    boxShadow: [
                      if (!isHighContrast)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            color: isHighContrast
                                ? Colors.yellow
                                : (isAlert ? alertColor : infoColor),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isAlert
                                        ? Icons.warning_amber_rounded
                                        : Icons.info_outline,
                                    color: isHighContrast
                                        ? Colors.yellow
                                        : (isAlert ? alertColor : infoColor),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isHighContrast
                                            ? Colors.yellow
                                            : const Color(0xFF2D2D2D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
