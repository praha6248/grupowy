import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'services/local_notifications.dart';
import 'screens/blood_saturation_screen.dart';
import 'connection/api_service.dart'; // DODANO: Import Twojego API

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pl_PL', null);
  await LocalNotifications.init();

  await setupAndStartTor();

  // DODANO: Wywołanie testu zaraz po starcie Tora
  _runInitialTest();

  runApp(const MyApp());
}

// DODANO: Prosta funkcja testowa widoczna w konsoli
Future<void> _runInitialTest() async {
  debugPrint("Rozpoczynam test połączenia z API...");
  try {
    final api = ApiService();
    final pomiar = await api.getOstatniPomiar();
    debugPrint(
      "✅ TEST API UDANY: Tętno ${pomiar.tetno}, Saturacja ${pomiar.saturacja}",
    );
  } catch (e) {
    debugPrint("❌ TEST API NIEUDANY: $e");
  }
}

Future<void> setupAndStartTor() async {
  try {
    final directory = await getApplicationSupportDirectory();
    final torPath = '${directory.path}\\tor.exe';
    final torFile = File(torPath);

    if (!await torFile.exists()) {
      debugPrint("Wypakowuję silnik Tor z zasobów...");
      final data = await rootBundle.load('assets/bin/tor.exe');
      final bytes = data.buffer.asUint8List();
      await torFile.writeAsBytes(bytes);
      debugPrint("Wypakowano do: $torPath");
    }

    debugPrint("Uruchamiam proces Tor w tle...");

    await Process.start(torPath, ['--SocksPort', '9050']);

    debugPrint("Tor zainicjowany poprawnie na porcie 9050");
  } catch (e) {
    debugPrint("KRYTYCZNY BŁĄD TORA: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartHelp',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF669D)),
        fontFamily: 'Roboto',
      ),
      home: const BloodSaturationScreen(),
    );
  }
}
