import 'dart:async'; // Potrzebne do Timera
import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/theme_service.dart';
import '../connection/api_service.dart';
import '../connection/pomiar_model.dart';
import '../services/notification_service.dart'; // Twój serwis wewnętrzny
import '../services/local_notifications.dart';   // Twój serwis powiadomień systemowych

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Zdarzenie> _zdarzenia = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer; // Timer do automatycznego odświeżania
  final ApiService _apiService = ApiService();
  
  // Zapamiętujemy datę/ID ostatniego zdarzenia, aby telefon nie wibrował co 4 sekundy na to samo zdarzenie
  String? _lastProcessedEventTime; 

  @override
  void initState() {
    super.initState();
    _fetchData(); // Pierwsze pobranie danych przy wejściu
    
    // Odświeżaj dane co 4 sekundy automatycznie
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Zatrzymanie timera przy wyjściu z ekranu
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getZdarzenia(limit: 20);
      
      if (data.isNotEmpty) {
        final najnowszeZdarzenie = data.first;
        
        bool isKrytyczne = najnowszeZdarzenie.typ_zdarzenia.toLowerCase().contains('upadek') ||
                           najnowszeZdarzenie.typ_zdarzenia.toLowerCase().contains('krytyczne');

        // Sprawdzamy czy to zupełnie nowe zdarzenie, którego jeszcze nie przetwarzaliśmy
        if (isKrytyczne && _lastProcessedEventTime != najnowszeZdarzenie.data) {
          _lastProcessedEventTime = najnowszeZdarzenie.data;
          
          DateTime dt = DateTime.tryParse(najnowszeZdarzenie.data) ?? DateTime.now();
          String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          
          // 1. Dodanie do czerwonej kropki przy dzwonku w aplikacji
          NotificationService().addNotification(
            "ALARM: ${najnowszeZdarzenie.typ_zdarzenia}", 
            timeStr
          );

          // 2. Wysłanie fizycznego powiadomienia na system Android (z dźwiękiem)
          LocalNotifications.showInstantNotification(
            id: najnowszeZdarzenie.hashCode, // unikalne ID powiadomienia
            title: "⚠️ WYKRYTO ZAGROŻENIE!",
            body: "${najnowszeZdarzenie.typ_zdarzenia} (Godzina: $timeStr)",
          );
        }
      }

      if (mounted) {
        setState(() {
          _zdarzenia = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
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
        return Scaffold(
          backgroundColor: isHighContrast ? Colors.black : const Color(0xFFF4F1F2),
          body: SafeArea(
            child: Column(
              children: [
                HeaderSection(
                  title: 'Aktywność i Zdarzenia',
                  showChartIcon: false,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildMainContent(isHighContrast),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 4),
        );
      },
    );
  }

  Widget _buildMainContent(bool isHighContrast) {
    if (_isLoading && _zdarzenia.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _zdarzenia.isEmpty) {
      return Center(
        child: Text(
          'Błąd: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_zdarzenia.isEmpty) {
      return const Center(
        child: Text('Brak zarejestrowanych zdarzeń.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 120.0),
      itemCount: _zdarzenia.length,
      itemBuilder: (context, index) {
        final event = _zdarzenia[index];

        DateTime dt = DateTime.tryParse(event.data) ?? DateTime.now();
        String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}  (${dt.day}.${dt.month})';

        bool isAlert = event.typ_zdarzenia.toLowerCase().contains('upadek') ||
                       event.typ_zdarzenia.toLowerCase().contains('krytyczne');

        return _buildTimelineItem(
          time: timeStr,
          title: event.typ_zdarzenia,
          isAlert: isAlert,
          isHighContrast: isHighContrast,
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
                    border: isHighContrast ? Border.all(color: Colors.yellow, width: 1) : null,
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
                            color: isHighContrast ? Colors.yellow : (isAlert ? alertColor : infoColor),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    isAlert ? Icons.warning_amber_rounded : Icons.info_outline,
                                    color: isHighContrast ? Colors.yellow : (isAlert ? alertColor : infoColor),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isHighContrast ? Colors.yellow : const Color(0xFF2D2D2D),
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