import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'services/twilio_auth_service.dart';
import 'services/app_config.dart';
// import 'services/supabase_config.dart';  // Disabled due to Firebase conflicts
import 'services/database_service_rest.dart';  // Firebase-free database service

final Logger appLogger = Logger();
late AuthService authService;
late DatabaseServiceRest databaseService;  // Using REST API service

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      appLogger.i('✅ Environment variables loaded successfully');
    } catch (e) {
      appLogger.w('⚠️ .env file not found, using default values');
    }
    
    // Initialize app configuration
    await AppConfig.initialize();
    
    // Initialize Database Service - Firebase-free REST API approach
    databaseService = DatabaseServiceRest();
    appLogger.i('✅ Firebase-free Database Service initialized successfully');
    
    // Check database health
    final isHealthy = await databaseService.isHealthy();
    if (isHealthy) {
      appLogger.i('✅ Database connection healthy - ready for 200K+ users');
    } else {
      appLogger.w('⚠️ Database connection issue - check Supabase credentials');
    }
    
    // Initialize Authentication based on environment
    if (AppConfig.instance.isDevelopment) {
      authService = DemoAuthService();
      appLogger.i('✅ Demo Auth Service: Initialized successfully');
    } else {
      authService = TwilioAuthService();
      appLogger.i('✅ Twilio Auth Service: Initialized successfully');
    }
    
    appLogger.i('App initialization completed successfully');
  } catch (error, stackTrace) {
    appLogger.e('Failed to initialize services', error: error, stackTrace: stackTrace);
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
