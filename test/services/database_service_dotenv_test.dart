import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:exam_coach_app/services/database_service_rest.dart';

void main() {
  group('DatabaseServiceRest Dotenv Handling', () {
    late DatabaseServiceRest databaseService;

    setUp(() {
      databaseService = DatabaseServiceRest();
      // Clear any existing dotenv data
      dotenv.clean();
    });

    tearDown(() {
      // No dispose method available
    });

    group('When dotenv is not initialized', () {
      test('should handle dotenv NotInitializedError gracefully in _supabaseUrl', () {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // This should not throw, even when dotenv is not initialized
        expect(() => databaseService.testSupabaseUrl, returnsNormally);
        
        // Should return default URL when dotenv access fails
        final url = databaseService.testSupabaseUrl;
        expect(url, equals('https://your-project.supabase.co'));
      });

      test('should handle dotenv NotInitializedError gracefully in _supabaseAnonKey', () {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // This should not throw, even when dotenv is not initialized
        expect(() => databaseService.testSupabaseAnonKey, returnsNormally);
        
        // Should return default key when dotenv access fails
        final key = databaseService.testSupabaseAnonKey;
        expect(key, equals('your-anon-key'));
      });

      test('should handle dotenv NotInitializedError in _isConfigured', () {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // This should not throw, even when dotenv is not initialized
        expect(() => databaseService.testIsConfigured, returnsNormally);
        
        // Should return false when dotenv access fails
        final isConfigured = databaseService.testIsConfigured;
        expect(isConfigured, isFalse);
      });

      test('should work properly in test mode even when dotenv fails', () {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // Configure for testing - this should work regardless of dotenv
        databaseService.configureForTesting();
        
        expect(databaseService.testIsConfigured, isTrue);
        expect(databaseService.testSupabaseUrl, contains('test.supabase.co'));
        expect(databaseService.testSupabaseAnonKey, contains('test-key'));
      });

      test('should handle user lookup when dotenv is not initialized', () async {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // Configure for testing
        databaseService.configureForTesting();
        
        // This should work without throwing NotInitializedError
        final user = await databaseService.getUserByPhone('+1234567890');
        expect(user, isNull); // Should return null for non-existent user
      });
    });

    group('When dotenv fails and service auto-configures', () {
      test('should automatically configure for testing when dotenv access fails', () {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // When dotenv fails, the database service automatically falls back to test mode
        // This is the correct behavior to prevent NotInitializedError
        expect(databaseService.testSupabaseUrl, contains('test.supabase.co'));
        expect(databaseService.testSupabaseAnonKey, contains('test-key'));
        
        // The service should be configured (in test mode)
        expect(databaseService.testIsConfigured, isTrue);
      });

      test('should handle health check when not configured', () async {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // Don't configure for testing - this will try to connect to default URLs
        // The important part is that it doesn't throw NotInitializedError
        // It should gracefully fail and return false
        final isHealthy = await databaseService.isHealthy();
        expect(isHealthy, isFalse); // Should not be healthy when trying to connect to non-existent server
      });
    });

    group('Error handling during operations', () {
      test('should gracefully handle errors during user operations when dotenv fails', () async {
        // Ensure dotenv is not loaded
        dotenv.clean();
        
        // Don't configure for testing - this simulates the real error condition
        
        // These operations should handle the error gracefully and not crash
        // We expect them to return null or false, not throw exceptions
        final user = await databaseService.getUserByPhone('+1234567890');
        expect(user, isNull);
        
        final userByEmail = await databaseService.getUserByEmail('test@example.com');
        expect(userByEmail, isNull);
        
        final isHealthy = await databaseService.isHealthy();
        expect(isHealthy, isFalse);
      });
    });
  });
}

