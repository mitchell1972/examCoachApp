import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'services/twilio_auth_service.dart';
import 'services/app_config.dart';
import 'services/storage_service.dart';
// import 'services/supabase_config.dart';  // Disabled due to Firebase conflicts
import 'services/database_service_rest.dart';  // Firebase-free database service

final Logger appLogger = Logger();
late AuthService authService;
late DatabaseServiceRest databaseService;  // Using REST API service
late StorageService storageService;

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
    
    // Check environment variables and configure database service
    String? supabaseUrl;
    String? supabaseKey;
    
    try {
      supabaseUrl = dotenv.env['SUPABASE_URL'];
      supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
    } catch (e) {
      // dotenv not initialized - no .env file found
      appLogger.w('⚠️ Environment variables not available: $e');
      supabaseUrl = null;
      supabaseKey = null;
    }
    
    appLogger.i('🔍 Environment check:');
    appLogger.i('  SUPABASE_URL: ${supabaseUrl ?? 'null'}');
    appLogger.i('  SUPABASE_ANON_KEY: ${supabaseKey?.isNotEmpty == true ? 'present' : 'null/empty'}');
    
    // Configure database service for demo mode if no valid credentials
    bool needsDemoMode = supabaseUrl == null || 
                        supabaseKey == null || 
                        supabaseUrl.contains('your-project') || 
                        supabaseKey.contains('your-anon-key') ||
                        supabaseUrl.isEmpty ||
                        supabaseKey.isEmpty;
    
    if (needsDemoMode) {
      databaseService.configureForTesting();
      appLogger.i('✅ Database Service configured for DEMO MODE (no valid .env credentials)');
    } else {
      appLogger.i('✅ Firebase-free Database Service initialized with production config');
      
      // Check database health only if we have real credentials
      final isHealthy = await databaseService.isHealthy();
      if (isHealthy) {
        appLogger.i('✅ Database connection healthy - ready for 200K+ users');
      } else {
        appLogger.w('⚠️ Database connection issue - check Supabase credentials');
      }
    }
    
    // Initialize Storage Service and load existing users for duplicate checking
    storageService = StorageService();
    await storageService.initialize();
    
    // Initialize Authentication based on environment
    appLogger.i('🔍 Initializing Auth Service - Environment: ${AppConfig.instance.environment.name}');
    appLogger.i('🔍 Is Development: ${AppConfig.instance.isDevelopment}');
    appLogger.i('🔍 Is Production: ${AppConfig.instance.isProduction}');
    appLogger.i('🔍 kDebugMode: $kDebugMode');
    appLogger.i('🔍 kReleaseMode: $kReleaseMode');
    appLogger.i('🔍 kProfileMode: $kProfileMode');
    
    // Check environment variables
    appLogger.i('🔍 Environment Variables:');
    appLogger.i('  VERCEL: ${const String.fromEnvironment('VERCEL')}');
    appLogger.i('  VERCEL_ENV: ${const String.fromEnvironment('VERCEL_ENV')}');
    appLogger.i('  NODE_ENV: ${const String.fromEnvironment('NODE_ENV')}');
    appLogger.i('  FLUTTER_ENV: ${const String.fromEnvironment('FLUTTER_ENV')}');
    appLogger.i('  CI: ${const String.fromEnvironment('CI')}');
    appLogger.i('  GITHUB_ACTIONS: ${const String.fromEnvironment('GITHUB_ACTIONS')}');
    
    if (AppConfig.instance.isDevelopment) {
      authService = DemoAuthService();
      appLogger.i('✅ Demo Auth Service: Initialized successfully');
    } else {
      authService = TwilioAuthService();
      appLogger.i('✅ Twilio Auth Service: Initialized successfully');
    }
    
    appLogger.i('✅ Auth Service Type: ${authService.runtimeType}');
    appLogger.i('✅ Auth Service is Demo: ${authService is DemoAuthService}');
    appLogger.i('✅ Auth Service is Twilio: ${authService is TwilioAuthService}');
    
    appLogger.i('App initialization completed successfully');
  } catch (error, stackTrace) {
    appLogger.e('Failed to initialize services', error: error, stackTrace: stackTrace);
    // Fall back to demo mode if initialization fails
    databaseService = DatabaseServiceRest();
    databaseService.configureForTesting();
    storageService = StorageService();
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
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
