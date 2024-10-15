// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splashscreen.dart';
import 'plantselectionpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCzYlKEe8mbF3Y-k-hw_MXs-O2qNy38uIA",
        authDomain: "plantprojectapp.firebaseapp.com",
        databaseURL: "https://plantprojectapp-default-rtdb.firebaseio.com",
        projectId: "plantprojectapp",
        storageBucket: "plantprojectapp.appspot.com",
        messagingSenderId: "606886870127",
        appId: "1:606886870127:web:9b5f616a7d7abf95e9a19a",
        measurementId: "G-8VGQCD9HHH",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => PlantSelectionPage(),
      },
    );
  }
}
