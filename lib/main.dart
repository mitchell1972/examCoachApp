import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_config.dart';
import 'services/auth_service.dart';

final Logger appLogger = Logger();
late AuthService authService;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize app configuration
    await AppConfig.initialize();
    
    // Initialize Authentication Service
    authService = DemoAuthService();
    appLogger.i('✅ Auth Service: Initialized successfully');
    
    appLogger.i('App initialization completed successfully');
  } catch (error, stackTrace) {
    appLogger.e('Failed to initialize Auth Service', error: error, stackTrace: stackTrace);
    // Fall back to demo mode if initialization fails
    authService = DemoAuthService();
    appLogger.w('⚠️ Falling back to Demo Auth Service');
  }
  
  runApp(const ExamCoachApp());
}

class ExamCoachApp extends StatelessWidget {
  const ExamCoachApp({super.key});

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
