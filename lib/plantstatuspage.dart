import 'dart:convert'; // For json decoding
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle to load assets
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class PlantStatusPage extends StatefulWidget {
  final String plantName;
  final String plantImage;

  const PlantStatusPage({Key? key, required this.plantName, required this.plantImage}) : super(key: key);

  @override
  _PlantStatusPageState createState() => _PlantStatusPageState();
}

class _PlantStatusPageState extends State<PlantStatusPage> {
  String plantStatus = 'Loading...';
  int hydrationLevel = 0;
  int moistureLevel = 0;
  int points = 0;
  DateTime? lastWatered;
  DateTime? reminderDateTime; // Track both date and time for the reminder
  bool isLoading = true;
  bool hasError = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Timer? _timer;
  List<String> plantTips = [];

  int maxPoints = 100;
  Duration minInterval = Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _fetchPlantData();
    _startAutoRefresh();
    _loadPlantTips();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchPlantData();
    });
  }

  int calculatePoints(DateTime wateredTime) {
    if (reminderDateTime == null) return 0;
    Duration difference = wateredTime.difference(reminderDateTime!).abs();
    if (difference > minInterval) return 0;
    int deductedPoints = (difference.inMinutes * maxPoints) ~/ minInterval.inMinutes;
    return max(0, maxPoints - deductedPoints);
  }

  void _waterPlantToday() async {
    DateTime now = DateTime.now();
    int rewardPoints = calculatePoints(now);
    setState(() {
      lastWatered = now;
      points += rewardPoints;
    });
    await _database.child('plant1/lastWatered').set(now.toIso8601String());
    await _database.child('plant1/points').set(points);
  }

  Future<void> _setReminder() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await _database.child('plant1/reminderDateTime').set(fullDateTime.toIso8601String());
        setState(() {
          reminderDateTime = fullDateTime;
        });
      }
    }
  }

  void _fetchPlantData() async {
    try {
      final snapshot = await _database.child('plant1').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        setState(() {
          plantStatus = data['healthStatus'] ?? 'Unknown';
          hydrationLevel = data['hydration'] ?? 0;

          if (data['moisture'] != null) {
            var moistureValue = data['moisture'];
            if (moistureValue is String) {
              moistureLevel = double.parse(moistureValue).toInt();
            } else if (moistureValue is int) {
              moistureLevel = moistureValue;
            } else if (moistureValue is double) {
              moistureLevel = moistureValue.toInt();
            }
          }

          points = data['points'] ?? 0;
          lastWatered = DateTime.parse(data['lastWatered'] ?? DateTime.now().toIso8601String());
          if (data['reminderDateTime'] != null) {
            reminderDateTime = DateTime.parse(data['reminderDateTime']);
          }

          // Debugging: Print the dates for verification
          print('Last Watered: $lastWatered');
          print('Reminder DateTime: $reminderDateTime');

          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          plantStatus = 'No data found';
          isLoading = false;
          hasError = true;
        });
      }
    } catch (error) {
      setState(() {
        plantStatus = 'Error loading data';
        isLoading = false;
        hasError = true;
      });
      print('Error fetching data: $error');
    }
  }

  Future<void> _loadPlantTips() async {
    try {
      final String response = await rootBundle.loadString('assets/planttips.json');
      final data = json.decode(response);
      setState(() {
        plantTips = List<String>.from(data['plants'][widget.plantName]['tips']);
      });
    } catch (error) {
      print('Error loading plant tips: $error');
    }
  }

  String _formatLastWateredTime() {
    if (lastWatered == null) return 'Not yet watered';
    Duration difference = DateTime.now().difference(lastWatered!);

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;
    int seconds = difference.inSeconds % 60;

    return 'Last watered on ${lastWatered!.toLocal()} (${days}d ${hours}h ${minutes}m ${seconds}s ago)';
  }

  Color _getLastWateredColor() {
    if (reminderDateTime == null || lastWatered == null) {
      return Colors.green; // Green by default if no reminder or no last watered date
    }

    // Ensure the reminder is after the last watered date and current time is past the reminder
    if (DateTime.now().isAfter(reminderDateTime!) && lastWatered!.isBefore(reminderDateTime!) && reminderDateTime!.isAfter(lastWatered!)) {
      return Colors.red;
    }

    return Colors.green;
  }

  String _formatReminderDateTime() {
    if (reminderDateTime == null) return 'No reminder set';
    Duration timeUntilReminder = reminderDateTime!.difference(DateTime.now());

    int days = timeUntilReminder.inDays;
    int hours = timeUntilReminder.inHours % 24;
    int minutes = timeUntilReminder.inMinutes % 60;

    return 'Next watering reminder: ${reminderDateTime!.toLocal()} (${days}d ${hours}h ${minutes}m from now)';
  }

  Color _getLevelColor(int level) {
    if (level <= 30) return Colors.red;
    if (level <= 70) return Colors.yellow;
    return Colors.green;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'underwatered':
        return Colors.red;
      case 'overwatered':
        return Colors.yellow;
      case 'healthy':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : hasError
            ? Text('Failed to load data', style: TextStyle(color: Colors.red))
            : SingleChildScrollView( // Make content scrollable
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Points Display
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Points: $points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Last watered time
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatLastWateredTime(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getLastWateredColor(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Plant image
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.asset(
                        widget.plantImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: 200,
                      alignment: Alignment.center,
                      color: Colors.black54,
                      child: Text(
                        widget.plantName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Stats and Hydration/Moisture side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Plant Stats Box
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Plant Stats:',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Health: $plantStatus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(plantStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    // Hydration/Moisture Box
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Hydration: $hydrationLevel%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(hydrationLevel),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Moisture: $moistureLevel%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(moistureLevel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Reminder section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatReminderDateTime(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _setReminder,
                  child: Text('Set Watering Reminder'),
                ),
                SizedBox(height: 20),
                // "Watered Today" button
                ElevatedButton(
                  onPressed: _waterPlantToday,
                  child: Text('Watered Today'),
                ),
                SizedBox(height: 20),
                // Tips section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Care Tips:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: plantTips.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              "- ${plantTips[index]}",
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}