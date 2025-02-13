import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(ScheduleApp());
}

class ScheduleApp extends StatefulWidget {
  const ScheduleApp({super.key});

  @override
  _ScheduleAppState createState() => _ScheduleAppState();
}

class _ScheduleAppState extends State<ScheduleApp> {
  int _selectedIndex = 0;
  bool isDarkMode = true;
  DateTime? selectedDate;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  ThemeData _getTheme() {
    return isDarkMode
        ? ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          )
        : ThemeData.light();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_selectedIndex == 0) {
      body = DashboardScreen(onScheduleSelected: (DateTime date) {
        setState(() {
          _selectedIndex = 1;
          selectedDate = date;
        });
      });
    } else if (_selectedIndex == 1) {
      body = ScheduleScreen(selectedDate: selectedDate ?? DateTime.now());
    } else {
      body = const Center(child: Text('Settings Screen'));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("CSE 17"),
          backgroundColor: isDarkMode ? Colors.black54 : Colors.blue,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white70,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final String scheduleJson;

  const CountdownWidget({super.key, required this.scheduleJson});

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  String nextClass = "No upcoming class";
  String location = "";
  String countdown = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    final schedule = json.decode(widget.scheduleJson);

    DateTime? nextClassTime;
    String? nextSubject;
    String? nextLocation;

    if (schedule.containsKey(today)) {
      final classes = schedule[today] as List;
      for (var cls in classes) {
        final classTime = DateFormat('HH:mm').parse(cls['time']);
        final fullClassTime = DateTime(
            now.year, now.month, now.day, classTime.hour, classTime.minute);
        if (fullClassTime.isAfter(now)) {
          nextClassTime = fullClassTime;
          nextSubject = cls['subject'];
          nextLocation = cls['location'];
          break;
        }
      }
    }

    if (nextClassTime == null) {
      List<String> weekdays = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ];
      int todayIndex = weekdays.indexOf(today);

      for (int i = 1; i < 7; i++) {
        String nextDay = weekdays[(todayIndex + i) % 7];
        if (schedule.containsKey(nextDay)) {
          final classes = schedule[nextDay] as List;
          var cls = classes.first;
          final classTime = DateFormat('HH:mm').parse(cls['time']);
          // Instead of using copyWith (which doesn't exist for DateTime), create a new DateTime:
          DateTime nextDayDate = now.add(Duration(days: i));
          nextClassTime = DateTime(nextDayDate.year, nextDayDate.month,
              nextDayDate.day, classTime.hour, classTime.minute);
          nextSubject = cls['subject'];
          nextLocation = cls['location'];
          break;
        }
      }
    }

    if (nextClassTime != null) {
      final duration = nextClassTime.difference(now);
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      final minutes = duration.inMinutes % 60;

      setState(() {
        nextClass = nextSubject!;
        location = nextLocation!;
        countdown =
            "Starts in ${days > 0 ? "$days days, " : ""}$hours hrs, $minutes min";
      });
    } else {
      setState(() {
        nextClass = "No upcoming class";
        location = "";
        countdown = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Next Class:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(nextClass, style: const TextStyle(fontSize: 20)),
            if (location.isNotEmpty)
              Text("Location: $location", style: const TextStyle(fontSize: 14)),
            if (countdown.isNotEmpty)
              Text(countdown,
                  style: const TextStyle(fontSize: 14, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Function(DateTime) onScheduleSelected;

  const DashboardScreen({super.key, required this.onScheduleSelected});

  DateTime getNextWorkingDay() {
    // For simplicity, tomorrow is always considered the next working day.
    return DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    DateTime nextDay = getNextWorkingDay();
    String nextDayName = DateFormat('EEEE').format(nextDay);

    String scheduleJson = jsonEncode({
      "Monday": [
        {"time": "11:00", "subject": "OS", "location": "WL 103"},
        {"time": "12:00", "subject": "OS(L)", "location": "WL 103"},
        {"time": "13:00", "subject": "OS(L)", "location": "WL 103"},
        {"time": "15:00", "subject": "OB", "location": "LH 202"},
        {"time": "16:00", "subject": "DM", "location": "LH 202"},
        {"time": "17:00", "subject": "COA", "location": "LH 202"}
      ],
      "Tuesday": [
        {"time": "12:00", "subject": "VT", "location": "-N.A-"},
        {"time": "13:00", "subject": "VT", "location": "-N.A-"},
        {"time": "15:00", "subject": "OS", "location": "LH 206"},
        {"time": "16:00", "subject": "DM", "location": "LH 206"}
      ],
      "Wednesday": [
        {"time": "11:00", "subject": "DM", "location": "LH 208"},
        {"time": "12:00", "subject": "COA", "location": "LH 208"},
        {"time": "13:00", "subject": "OOPJ", "location": "LH 208"},
        {"time": "15:00", "subject": "DBMS", "location": "LH 303"},
        {"time": "16:00", "subject": "OOPJ(L)", "location": "WL 202"}
      ],
      "Thursday": [
        {"time": "11:00", "subject": "OOPJ", "location": "LH 205"},
        {"time": "12:00", "subject": "DM", "location": "LH 205"},
        {"time": "13:00", "subject": "OB", "location": "LH 205"},
        {"time": "15:00", "subject": "OS", "location": "LH 201"},
        {"time": "16:00", "subject": "DBMS", "location": "LH 201"},
        {"time": "17:00", "subject": "COA", "location": "LH 201"}
      ],
      "Friday": [
        {"time": "09:00", "subject": "OB", "location": "LH 303"},
        {"time": "10:00", "subject": "OOPJ", "location": "LH 303"},
        {"time": "14:00", "subject": "DBMS(L)", "location": "WL 101"},
        {"time": "15:00", "subject": "DBMS(L)", "location": "WL 101"},
        {"time": "16:00", "subject": "COA", "location": "LH 201"},
        {"time": "17:00", "subject": "DBMS", "location": "LH 201"}
      ]
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).cardColor,
              ),
              child: CountdownWidget(scheduleJson: scheduleJson),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                        child: Text('Assignments',
                            style: TextStyle(fontSize: 18))),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                        child: Text('Quizzes', style: TextStyle(fontSize: 18))),
                  ),
                ),
                GestureDetector(
                  onTap: () => onScheduleSelected(nextDay),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "Tomorrow's Schedule ($nextDayName)",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                        child: Text('Add New Task',
                            style: TextStyle(fontSize: 18))),
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

class ScheduleScreen extends StatefulWidget {
  final DateTime selectedDate;
  const ScheduleScreen({super.key, required this.selectedDate});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime selectedDate;
  final Map<String, List<String>> schedule = {
    'Monday': [
      'OS   (WL 103)   : 11AM TO 12 PM',
      'OS-LAB (WL 103) : 12PM TO 02 PM',
      '----break---',
      'OB (LH 202)',
      'DM (LH 202)',
      'COA (LH 202)'
    ],
    'Tuesday': [
      'VT(L) : 12PM TO 2AM',
      '--------BREAK------',
      'OS (LH 206) : 3PM TO 4PM',
      'DM (LH 206) : 4PM TO 5PM'
    ],
    'Wednesday': [
      'DM (LH 208)  : 11AM TO 12PM',
      'COA (LH 208) : 12PM TO  1PM',
      'OOPJ (LH 208):  1PM TO  2PM',
      '-----------BREAK-----------',
      'DBMS (LH 303):  3PM TO  4PM',
      'OOPJ (WL 202):  4PM TO  6PM'
    ],
    'Thursday': [
      'OOPJ (LH 205)',
      'DM (LH 205)',
      'OB (LH 205)',
      'OS (LH 201)',
      'DBMS (LH 201)'
    ],
    'Friday': [
      'OB (LH 303)  : 9AM TO 10AM ',
      'OOPJ (LH 303):10AM TO 11AM',
      '-----------BREAK------------',
      'DBMS(L) (WL 101): 2PM TO 4PM',
      'COA (LH 201) : 4PM TO 5PM'
    ],
  };

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String dayOfWeek = DateFormat('EEEE').format(selectedDate);
    List<String> daySchedule = schedule[dayOfWeek] ?? ['No classes today'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: daySchedule.length,
              itemBuilder: (context, index) {
                return ScheduleCard(title: daySchedule[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final String title;
  const ScheduleCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
