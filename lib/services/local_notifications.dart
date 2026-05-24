import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotifications {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // DODAJ TĘ METODĘ DO KLASY LocalNotifications
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Kanał o najwyższym priorytecie (Importance.max) wymusza pojawienie się baneru i dźwięku
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_critical_alerts',
          'Alerty Krytyczne SmartHelp',
          channelDescription:
              'Natychmiastowe powiadomienia o zagrożeniu życia i upadkach',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true, // Wymuszenie dźwięku
          enableVibration: true, // Wymuszenie wibracji
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, platformDetails);
      print("SUKCES: Wyświetlono powiadomienie natychmiastowe");
    } catch (e) {
      print("BŁĄD wyświetlania powiadomienia natychmiastowego: $e");
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
    } catch (e) {
      print("Błąd ustawiania strefy czasowej (może być domyślna): $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
          defaultActionName: 'Otwórz powiadomienie',
          defaultIcon: AssetsLinuxIcon('assets/app_icon.png'),
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Kliknięto powiadomienie: ${details.payload}");
      },
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_smarthelp',
          'SmartHelp Przypomnienia',
          channelDescription: 'Kanał powiadomień dla przypomnień z kalendarza',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // KONWERSJA DATY NA STREFĘ CZASOWĄ
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    print("DEBUG: Próba zaplanowania na: $tzScheduledDate");
    print("DEBUG: Aktualny czas telefonu: ${tz.TZDateTime.now(tz.local)}");

    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print("UWAGA: Data jest w przeszłości! Powiadomienie może nie przyjść.");
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        platformDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // TO JEST KLUCZOWE
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print(
        "SUKCES: Zaplanowano powiadomienie na ${tzScheduledDate.toString()}",
      );
    } catch (e) {
      print("BŁĄD planowania: $e");
    }
  }
}
