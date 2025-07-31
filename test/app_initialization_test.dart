import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:exam_coach_app/services/database_service_rest.dart';

void main() {
  group('App Initialization Dotenv Handling', () {
    late DatabaseServiceRest databaseService;

    setUp(() {
      // Clear any existing dotenv data
      dotenv.clean();
    });

    tearDown(() {
      // No dispose method available
    });

    test('should handle app initialization when .env file does not exist', () async {
      // Simulate the scenario where dotenv.load() was attempted but no .env file exists
      dotenv.clean();
      
      // This simulates the initialization logic from main.dart
      databaseService = DatabaseServiceRest();
      
      // Check environment variables with proper error handling
      String? supabaseUrl;
      String? supabaseKey;
      
      try {
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
      } catch (e) {
        // dotenv not initialized - no .env file found
        supabaseUrl = null;
        supabaseKey = null;
      }
      
      // These should be null when dotenv is not initialized
      expect(supabaseUrl, isNull);
      expect(supabaseKey, isNull);
      
      // Configure database service for demo mode
      bool needsDemoMode = supabaseUrl == null || 
                          supabaseKey == null || 
                          (supabaseUrl?.contains('your-project') ?? false) || 
                          (supabaseKey?.contains('your-anon-key') ?? false) ||
                          (supabaseUrl?.isEmpty ?? true) ||
                          (supabaseKey?.isEmpty ?? true);
      
      expect(needsDemoMode, isTrue);
      
      if (needsDemoMode) {
        databaseService.configureForTesting();
      }
      
      // Database service should be properly configured for demo mode
      expect(databaseService.testIsConfigured, isTrue);
      expect(databaseService.testSupabaseUrl, contains('test.supabase.co'));
      expect(databaseService.testSupabaseAnonKey, contains('test-key'));
    });

    test('should properly handle demo mode detection logic', () async {
      // Test the demo mode detection logic without relying on dotenv.env manipulation
      databaseService = DatabaseServiceRest();
      
      // The important part is testing the demo mode detection logic
      String? supabaseUrl = null;
      String? supabaseKey = null;
      
      // Simulate no environment variables available
      bool needsDemoMode = supabaseUrl == null || 
                          supabaseKey == null || 
                          (supabaseUrl?.contains('your-project') ?? false) || 
                          (supabaseKey?.contains('your-anon-key') ?? false) ||
                          (supabaseUrl?.isEmpty ?? true) ||
                          (supabaseKey?.isEmpty ?? true);
      
      expect(needsDemoMode, isTrue);
      
      // Simulate placeholder values
      supabaseUrl = 'https://your-project.supabase.co';
      supabaseKey = 'your-anon-key';
      
      needsDemoMode = supabaseUrl == null || 
                      supabaseKey == null || 
                      (supabaseUrl?.contains('your-project') ?? false) || 
                      (supabaseKey?.contains('your-anon-key') ?? false) ||
                      (supabaseUrl?.isEmpty ?? true) ||
                      (supabaseKey?.isEmpty ?? true);
      
      expect(needsDemoMode, isTrue);
      
      // Simulate valid values
      supabaseUrl = 'https://valid-project.supabase.co';
      supabaseKey = 'valid-anon-key-123456789';
      
      needsDemoMode = supabaseUrl == null || 
                      supabaseKey == null || 
                      (supabaseUrl?.contains('your-project') ?? false) || 
                      (supabaseKey?.contains('your-anon-key') ?? false) ||
                      (supabaseUrl?.isEmpty ?? true) ||
                      (supabaseKey?.isEmpty ?? true);
      
      expect(needsDemoMode, isFalse);
    });

    test('should handle user operations after proper initialization', () async {
      // Simulate app initialization
      dotenv.clean();
      
      databaseService = DatabaseServiceRest();
      databaseService.configureForTesting();
      
      // These operations should work without throwing NotInitializedError
      final user = await databaseService.getUserByPhone('+447940361848');
      expect(user, isNull);
      
      final isHealthy = await databaseService.isHealthy();
      expect(isHealthy, isFalse); // Will be false due to network failure in test environment
    });

    test('should handle registration flow with proper phone validation', () async {
      // Simulate app initialization
      dotenv.clean();
      
      databaseService = DatabaseServiceRest();
      databaseService.configureForTesting();
      
      // Test with valid phone number
      final userValid = await databaseService.getUserByPhone('+447940361848');
      expect(userValid, isNull); // No user should exist in test mode
      
      // Test with empty phone number - this should be handled gracefully
      try {
        final userEmpty = await databaseService.getUserByPhone('');
        expect(userEmpty, isNull);
      } catch (e) {
        // This is acceptable - the service may throw an error for empty phone numbers
        expect(e.toString(), contains('phone'));
      }
      
      // Test health check works
      final isHealthy = await databaseService.isHealthy();
      expect(isHealthy, isFalse); // Will be false due to network failure in test environment
    });
  });
}