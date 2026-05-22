import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_widgets.dart';
import '../widgets/notification_bell.dart';
import '../services/notification_service.dart';
import '../services/local_notifications.dart';
import '../services/theme_service.dart';

enum RecurrenceType { none, daily, weekly, monthly }

class CalendarEvent {
  final String title;
  final TimeOfDay time;
  final RecurrenceType recurrence;

  CalendarEvent(this.title, this.time, {this.recurrence = RecurrenceType.none});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'recurrence': recurrence.index,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      json['title'],
      TimeOfDay(hour: json['hour'], minute: json['minute']),
      recurrence: RecurrenceType.values[json['recurrence'] ?? 0],
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString('calendar_events');
    if (eventsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(eventsJson);
      final Map<DateTime, List<CalendarEvent>> loadedEvents = {};

      decoded.forEach((key, value) {
        final DateTime date = DateTime.parse(key);
        final List<CalendarEvent> list = (value as List)
            .map((e) => CalendarEvent.fromJson(e))
            .toList();
        loadedEvents[date] = list;
      });

      setState(() {
        _events = loadedEvents;
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> toEncode = {};

    _events.forEach((key, value) {
      toEncode[key.toIso8601String()] = value.map((e) => e.toJson()).toList();
    });

    await prefs.setString('calendar_events', jsonEncode(toEncode));
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  String _formatTime24(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  void _showAddEventDialog() {
    String newTitle = "";
    TimeOfDay selectedTime = TimeOfDay.now();
    RecurrenceType selectedRecurrence = RecurrenceType.none;

    final bool isHighContrast = ThemeService().isHighContrast.value;
    final Color minimalBlack = const Color(0xFF1E1E1E);
    final Color primaryActionColor = isHighContrast
        ? Colors.yellow
        : minimalBlack;
    final Color textColor = isHighContrast
        ? Colors.yellow
        : const Color(0xFF2D2D2D);
    final Color bgColor = isHighContrast ? Colors.black : Colors.white;
    final Color subTextColor = isHighContrast ? Colors.yellow : Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: bgColor,
              surfaceTintColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isHighContrast
                    ? const BorderSide(color: Colors.yellow)
                    : BorderSide.none,
              ),
              title: Text(
                "Dodaj przypomnienie",
                style: TextStyle(color: textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Treść przypomnienia",
                        labelStyle: TextStyle(color: subTextColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryActionColor,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: subTextColor),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      cursorColor: primaryActionColor,
                      onChanged: (val) => newTitle = val,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Godzina: ${_formatTime24(selectedTime)}",
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5757DB),
                          ),
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: isHighContrast
                                      ? ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Colors.yellow,
                                            onPrimary: Colors.black,
                                            surface: Colors.black,
                                            onSurface: Colors.yellow,
                                          ),
                                        )
                                      : ThemeData.light().copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: minimalBlack,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                  child: MediaQuery(
                                    data: MediaQuery.of(
                                      context,
                                    ).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  ),
                                );
                              },
                            );
                            if (picked != null)
                              setStateDialog(() => selectedTime = picked);
                          },
                          child: const Text("Ustaw"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Powtarzalność:",
                      style: TextStyle(fontSize: 14, color: subTextColor),
                    ),
                    DropdownButton<RecurrenceType>(
                      value: selectedRecurrence,
                      dropdownColor: bgColor,
                      isExpanded: true,
                      style: TextStyle(color: textColor),
                      iconEnabledColor: primaryActionColor,
                      items: const [
                        DropdownMenuItem(
                          value: RecurrenceType.none,
                          child: Text("Brak"),
                        ),
                        DropdownMenuItem(
                          value: RecurrenceType.daily,
                          child: Text("Codziennie"),
                        ),
                        DropdownMenuItem(
                          value: RecurrenceType.weekly,
                          child: Text("Co tydzień"),
                        ),
                        DropdownMenuItem(
                          value: RecurrenceType.monthly,
                          child: Text("Co miesiąc"),
                        ),
                      ],
                      onChanged: (RecurrenceType? val) {
                        if (val != null)
                          setStateDialog(() => selectedRecurrence = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: isHighContrast
                        ? Colors.yellow
                        : Colors.grey,
                  ),
                  child: const Text("Anuluj"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    foregroundColor: isHighContrast
                        ? Colors.black
                        : Colors.white,
                  ),
                  onPressed: () async {
                    if (newTitle.isNotEmpty && _selectedDay != null) {
                      final dateKey = DateTime(
                        _selectedDay!.year,
                        _selectedDay!.month,
                        _selectedDay!.day,
                      );
                      final newEvent = CalendarEvent(
                        newTitle,
                        selectedTime,
                        recurrence: selectedRecurrence,
                      );

                      setState(() {
                        if (_events[dateKey] == null) {
                          _events[dateKey] = [newEvent];
                        } else {
                          _events[dateKey]!.add(newEvent);
                        }
                        // Sortowanie przypomnień chronologicznie według godziny
                        _events[dateKey]!.sort(
                          (a, b) => (a.time.hour * 60 + a.time.minute)
                              .compareTo(b.time.hour * 60 + b.time.minute),
                        );
                      });

                      _saveEvents();
                      Navigator.pop(context);

                      // Planowanie lokalnego powiadomienia systemowego
                      final DateTime scheduledDateTime = DateTime(
                        _selectedDay!.year,
                        _selectedDay!.month,
                        _selectedDay!.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      await LocalNotifications.scheduleNotification(
                        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        title: "Przypomnienie z kalendarza",
                        body: newTitle,
                        scheduledDate: scheduledDateTime,
                      );

                      // Dodanie do historii powiadomień wewnątrz aplikacji
                      await NotificationService().addNotification(
                        newTitle,
                        _formatTime24(selectedTime),
                      );
                    }
                  },
                  child: const Text("Dodaj"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEventDialog(CalendarEvent event, int index) {
    String newTitle = event.title;
    TimeOfDay newTime = event.time;

    final bool isHighContrast = ThemeService().isHighContrast.value;
    final Color minimalBlack = const Color(0xFF1E1E1E);
    final Color accentIndigo = const Color(0xFF5757DB);

    final Color primaryActionColor = isHighContrast
        ? Colors.yellow
        : minimalBlack;
    final Color textColor = isHighContrast
        ? Colors.yellow
        : const Color(0xFF2D2D2D);
    final Color bgColor = isHighContrast ? Colors.black : Colors.white;
    final Color subTextColor = isHighContrast ? Colors.yellow : Colors.grey;

    // FIX: Kontroler zdefiniowany tutaj zapobiega uciekaniu kursora podczas wpisywania tekstu
    final TextEditingController textController = TextEditingController(
      text: newTitle,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: bgColor,
              surfaceTintColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isHighContrast
                    ? const BorderSide(color: Colors.yellow)
                    : BorderSide.none,
              ),
              title: Text(
                "Edytuj przypomnienie",
                style: TextStyle(color: textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Co masz do zrobienia?",
                      labelStyle: TextStyle(color: subTextColor),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: primaryActionColor,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: subTextColor),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    cursorColor: primaryActionColor,
                    onChanged: (val) => newTitle = val,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Godzina: ${_formatTime24(newTime)}",
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: accentIndigo,
                        ),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: newTime,
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: isHighContrast
                                    ? ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Colors.yellow,
                                          onPrimary: Colors.black,
                                          surface: Colors.black,
                                          onSurface: Colors.yellow,
                                        ),
                                      )
                                    : ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: minimalBlack,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: minimalBlack,
                                          ),
                                        ),
                                      ),
                                child: MediaQuery(
                                  data: MediaQuery.of(
                                    context,
                                  ).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (picked != null)
                            setStateDialog(() => newTime = picked);
                        },
                        child: const Text("Zmień"),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_selectedDay != null) {
                      setState(() {
                        final dateKey = DateTime(
                          _selectedDay!.year,
                          _selectedDay!.month,
                          _selectedDay!.day,
                        );
                        if (_events[dateKey] != null) {
                          _events[dateKey]!.removeAt(index);
                          if (_events[dateKey]!.isEmpty) {
                            _events.remove(dateKey);
                          }
                        }
                      });
                      _saveEvents();
                      textController.dispose();
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Usuń"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    foregroundColor: isHighContrast
                        ? Colors.black
                        : Colors.white,
                  ),
                  onPressed: () async {
                    if (newTitle.isNotEmpty && _selectedDay != null) {
                      setState(() {
                        final dateKey = DateTime(
                          _selectedDay!.year,
                          _selectedDay!.month,
                          _selectedDay!.day,
                        );
                        if (_events[dateKey] != null) {
                          _events[dateKey]![index] = CalendarEvent(
                            newTitle,
                            newTime,
                            recurrence: event.recurrence,
                          );
                          _events[dateKey]!.sort(
                            (a, b) => (a.time.hour * 60 + a.time.minute)
                                .compareTo(b.time.hour * 60 + b.time.minute),
                          );
                        }
                      });

                      _saveEvents();
                      textController.dispose();
                      Navigator.pop(context);

                      await NotificationService().addNotification(
                        "Zaktualizowano: $newTitle",
                        _formatTime24(newTime),
                      );
                    }
                  },
                  child: const Text("Zapisz"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().isHighContrast,
      builder: (context, isHighContrast, child) {
        final Color minimalBlack = const Color(0xFF1E1E1E);
        final Color tileBg = isHighContrast ? Colors.black : Colors.white;
        final Color textColor = isHighContrast
            ? Colors.yellow
            : const Color(0xFF2D2D2D);
        final Color calendarTodayColor = isHighContrast
            ? Colors.grey.shade800
            : const Color(0xFFE2E7F3);
        final Color calendarSelectedColor = isHighContrast
            ? Colors.yellow
            : minimalBlack;

        return Scaffold(
          backgroundColor: isHighContrast
              ? Colors.black
              : const Color(0xFFF4F1F2),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HeaderSection(title: "Kalendarz", showChartIcon: false),
                      const NotificationBell(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(24),
                    border: isHighContrast
                        ? Border.all(color: Colors.yellow, width: 2)
                        : null,
                    boxShadow: [
                      if (!isHighContrast)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: textColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: textColor,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: isHighContrast ? Colors.yellow : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      weekendStyle: TextStyle(
                        color: isHighContrast
                            ? Colors.yellow
                            : Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: textColor),
                      weekendTextStyle: TextStyle(
                        color: isHighContrast
                            ? Colors.yellow
                            : Colors.redAccent,
                      ),
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: calendarTodayColor,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: isHighContrast ? Colors.yellow : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: calendarSelectedColor,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: isHighContrast ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: BoxDecoration(
                        color: isHighContrast
                            ? Colors.yellow
                            : const Color(0xFF5757DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Zadania na dziś",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: _showAddEventDialog,
                        icon: Icon(
                          Icons.add_circle,
                          size: 32,
                          color: isHighContrast ? Colors.yellow : minimalBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _getEventsForDay(_selectedDay ?? _focusedDay).isEmpty
                      ? Center(
                          child: Text(
                            "Brak przypomnień na ten dzień",
                            style: TextStyle(
                              color: isHighContrast
                                  ? Colors.yellow
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _getEventsForDay(
                            _selectedDay ?? _focusedDay,
                          ).length,
                          itemBuilder: (context, index) {
                            final event = _getEventsForDay(
                              _selectedDay ?? _focusedDay,
                            )[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: tileBg,
                                borderRadius: BorderRadius.circular(16),
                                border: isHighContrast
                                    ? Border.all(
                                        color: Colors.yellow,
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: [
                                  if (!isHighContrast)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHighContrast
                                        ? Colors.grey.shade900
                                        : const Color(0xFFEEF0F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _formatTime24(event.time),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isHighContrast
                                          ? Colors.yellow
                                          : const Color(0xFF5757DB),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                subtitle:
                                    event.recurrence != RecurrenceType.none
                                    ? Text(
                                        "Powtarzanie: ${event.recurrence.name}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isHighContrast
                                              ? Colors.yellow
                                              : Colors.grey,
                                        ),
                                      )
                                    : null,
                                trailing: Icon(
                                  Icons.edit_note,
                                  color: isHighContrast
                                      ? Colors.yellow
                                      : Colors.grey,
                                ),
                                onTap: () => _showEditEventDialog(event, index),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: const CustomBottomNavBar(activeIndex: 3),
        );
      },
    );
  }
}
