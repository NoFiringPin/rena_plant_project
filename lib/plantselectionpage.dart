import 'package:flutter/material.dart';
import 'plantstatuspage.dart'; // Import the PlantStatusPage here

class PlantSelectionPage extends StatefulWidget {
  @override
  _PlantSelectionPageState createState() => _PlantSelectionPageState();
}

class _PlantSelectionPageState extends State<PlantSelectionPage> {
  int currentIndex = 0;

  // List of plants with images and names
  final List<Map<String, String>> plants = [
    {'image': 'assets/aloe.jpg', 'name': 'Aloe Vera'},
    {'image': 'assets/snake.jpg', 'name': 'Snake Plant'},
    {'image': 'assets/spider.jpg', 'name': 'Spider Plant'},
    // Add more plants here as needed
  ];

  void _nextPlant() {
    setState(() {
      currentIndex = (currentIndex + 1) % plants.length;
    });
  }

  void _previousPlant() {
    setState(() {
      currentIndex = (currentIndex - 1 + plants.length) % plants.length;
    });
  }

  // Navigate to the PlantStatusPage with the selected plant
  void _goToPlantStatusPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantStatusPage(
          plantImage: plants[currentIndex]['image']!,
          plantName: plants[currentIndex]['name']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Title centered above the image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choose plant type below',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            // Plant image display with navigation arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: _previousPlant,
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.asset(
                    plants[currentIndex]['image']!,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: _nextPlant,
                ),
              ],
            ),
            SizedBox(height: 20),
            // Plant name caption
            Text(
              plants[currentIndex]['name']!,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Button to navigate to PlantStatusPage
            ElevatedButton(
              onPressed: _goToPlantStatusPage,
              child: Text('View Plant Status'),
            ),
          ],
        ),
      ),
    );
  }
}
