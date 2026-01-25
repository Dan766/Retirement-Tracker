import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RetirementTrackerApp());
}

class RetirementTrackerApp extends StatelessWidget {
  const RetirementTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retirement Income Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
