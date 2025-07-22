import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'screens/onboarding_screen.dart';
import 'services/firebase_auth_service.dart';

final Logger appLogger = Logger();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Authentication (environment-aware)
    await AuthService().initialize();
    appLogger.i('App initialization completed successfully');
  } catch (error, stackTrace) {
    appLogger.e('Failed to initialize Auth Service', error: error, stackTrace: stackTrace);
    // Continue with app launch even if auth fails (graceful degradation)
  }
  
  runApp(const ExamCoachApp());
}

class ExamCoachApp extends StatelessWidget {
  const ExamCoachApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Coach',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 