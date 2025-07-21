import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_config.dart';
import 'services/error_handler.dart';
import 'services/security_service.dart';

/// Global logger instance for the application
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeApp();
}

/// Initialize the application with proper error handling and security setup
Future<void> _initializeApp() async {
  try {
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      ErrorHandler.logError(details.exception, details.stack);
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandler.logError(error, stack);
      return true;
    };

    // Initialize security services
    await SecurityService.initialize();
    
    // Initialize app configuration
    await AppConfig.initialize();
    
    // Lock device orientation for security and UX consistency
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set secure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    appLogger.i('App initialization completed successfully');
    
    runApp(const ExamCoachApp());
  } catch (error, stackTrace) {
    appLogger.e('Failed to initialize app', error: error, stackTrace: stackTrace);
    
    // Run a minimal error app if main app fails to initialize
    runApp(
      MaterialApp(
        title: 'Error',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start the application',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Please restart the app'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExamCoachApp extends StatelessWidget {
  const ExamCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add providers here as the app grows
        ChangeNotifierProvider(create: (_) => AppConfig()),
      ],
      child: MaterialApp(
        title: 'Exam Coach App',
        

        
        // Security: Disable debug banner in production
        debugShowCheckedModeBanner: kDebugMode,
        
        // Theme configuration with security considerations
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          
          // Security: Disable text selection handles in sensitive areas
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Colors.deepPurple,
          ),
          
          // Accessibility improvements
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        
        // Use system theme preference
        themeMode: ThemeMode.system,
        
        // Navigation and routing
        home: const OnboardingScreen(),
        
        // Error handling for navigation
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Security: Limit text scale factor to prevent UI breaking
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
} 