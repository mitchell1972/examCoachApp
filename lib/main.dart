import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(ExamCoachApp());
}

class ExamCoachApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Coach',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 