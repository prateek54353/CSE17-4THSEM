import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(SheduleApp());
}

class SheduleApp extends StatefulWidget {
  const SheduleApp({super.key});

  @override
  _SheduleAppState createState() => _SheduleAppState();
}

class _SheduleAppState extends State<SheduleApp> {
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
            scaffoldBackgroundColor: Color(0xFF121212),
            cardColor: Color(0xFF1E1E1E),
          )
        : ThemeData.light();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("CSE 17"),
          backgroundColor: isDarkMode ? Colors.black54 : Colors.blue,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: _selectedIndex == 0
            ? DashboardScreen(onScheduleSelected: (DateTime date) {
                setState(() {
                  _selectedIndex = 1;
                  selectedDate = date;
                });
              })
            : ScheduleScreen(selectedDate: selectedDate ?? DateTime.now()),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white70,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
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
    _timer =
        Timer.periodic(Duration(seconds: 30), (timer) => _updateCountdown());
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

    // Check today's classes
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

    // If no class is found today, check upcoming days
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
        // Check the next 6 days
        String nextDay = weekdays[(todayIndex + i) % 7];
        if (schedule.containsKey(nextDay)) {
          final classes = schedule[nextDay] as List;
          var cls =
              classes.first; // Take the first class of the next available day
          final classTime = DateFormat('HH:mm').parse(cls['time']);
          nextClassTime = now
              .add(Duration(days: i))
              .copyWith(hour: classTime.hour, minute: classTime.minute);
          nextSubject = cls['subject'];
          nextLocation = cls['location'];
          break;
        }
      }
    }

    // Update state
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
      margin: EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Next Class:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(nextClass, style: TextStyle(fontSize: 20)),
            if (location.isNotEmpty)
              Text("Location: $location", style: TextStyle(fontSize: 14)),
            if (countdown.isNotEmpty)
              Text(countdown,
                  style: TextStyle(fontSize: 14, color: Colors.red)),
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
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    return now.add(Duration(days: currentWeekday == 7 ? 1 : 1));
  }

  @override
  Widget build(BuildContext context) {
    DateTime nextDay = getNextWorkingDay();
    String nextDayName = DateFormat('EEEE').format(nextDay);

    // Example schedule JSON (Replace this with actual schedule data)
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
      ]
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Long Widget (Next Class Countdown)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(
                      "assets/bgtilecountdown.jpg"), //  Background Image
                  fit: BoxFit.cover,
                ),
              ),
              child: Card(
                color: Colors.white.withOpacity(0.2), //  Slight Transparency
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  child: CountdownWidget(scheduleJson: scheduleJson),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),

          // Grid Widgets
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
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('Assignments',
                            style: TextStyle(fontSize: 18))),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('Quizzes', style: TextStyle(fontSize: 18))),
                  ),
                ),
                GestureDetector(
                  onTap: () => onScheduleSelected(nextDay),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "Tomorrow's Schedule ($nextDayName)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Center(
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
  DateTime selectedDate = DateTime.now();
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
              Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          SizedBox(height: 16),
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
        padding: EdgeInsets.all(16),
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
