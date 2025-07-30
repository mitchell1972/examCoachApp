import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/services/storage_service.dart';
import 'package:exam_coach_app/services/database_service_rest.dart';
import 'package:exam_coach_app/models/user_model.dart';
import 'package:exam_coach_app/services/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Duplicate User Validation Tests', () {
    late StorageService storageService;
    late DatabaseServiceRest databaseService;

    setUp(() async {
      // Initialize app configuration for tests
      await AppConfig.initialize();
      
      // Configure database service for testing
      databaseService = DatabaseServiceRest();
      databaseService.configureForTesting();
      databaseService.clearMockData(); // Clear any previous test data
      
      storageService = StorageService();
    });

    tearDown(() async {
      // Clean up mock data after each test
      databaseService.clearMockData();
    });

    test('Should allow registration for new phone number', () async {
      // Test with a unique phone number
      final duplicateMessage = await storageService.checkForDuplicateUser(
        phoneNumber: '+2348123456999', // Unique number
        email: 'newuser@example.com',
      );

      expect(duplicateMessage, isNull, reason: 'New user should be allowed to register');
    });

    test('Should validate phone number is required', () async {
      final duplicateMessage = await storageService.checkForDuplicateUser(
        phoneNumber: '', // Empty phone number
        email: 'test@example.com',
      );

      expect(duplicateMessage, 'Phone number is required');
    });

    test('Should validate phone number with whitespace', () async {
      final duplicateMessage = await storageService.checkForDuplicateUser(
        phoneNumber: '   ', // Whitespace only
        email: 'test@example.com',
      );

      expect(duplicateMessage, 'Phone number is required');
    });

    test('Should detect duplicate phone number', () async {
      // Add a mock user to the database
      final existingUser = UserModel(
        id: 'existing_user_123',
        fullName: 'Existing User',
        phoneNumber: '+2348123456788',
        email: 'existing@example.com',
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'trial',
        createdAt: DateTime.now(),
      );

      databaseService.addMockUser(existingUser);

      // Try to register with the same phone number
      final duplicateCheck = await storageService.checkForDuplicateUser(
        phoneNumber: '+2348123456788',
        email: 'newemail@example.com',
      );

      expect(duplicateCheck, isNotNull);
      expect(duplicateCheck, contains('phone number already exists'));
    });

    test('Should detect duplicate email address', () async {
      // Add a mock user to the database
      final existingUser = UserModel(
        id: 'existing_user_456',
        fullName: 'Existing User',
        phoneNumber: '+2348987654321',
        email: 'existing@example.com',
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'trial',
        createdAt: DateTime.now(),
      );

      databaseService.addMockUser(existingUser);

      // Try to register with the same email
      final duplicateCheck = await storageService.checkForDuplicateUser(
        phoneNumber: '+2348111222333',
        email: 'existing@example.com',
      );

      expect(duplicateCheck, isNotNull);
      expect(duplicateCheck, contains('email address already exists'));
    });

    test('Should handle registration flow with proper duplicate detection', () async {
      // Clear any existing mock data
      databaseService.clearMockData();
      
      final testUser = UserModel(
        id: 'test_user_123',
        fullName: 'Test User',
        phoneNumber: '+2348123456788',
        email: 'testuser@example.com',
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'trial',
        createdAt: DateTime.now(),
      );

      // First check should pass (no duplicates)
      final firstCheck = await storageService.checkForDuplicateUser(
        phoneNumber: testUser.phoneNumber!,
        email: testUser.email,
      );
      expect(firstCheck, isNull, reason: 'New user should be allowed');

      // Add user to mock database (simulating database save)
      databaseService.addMockUser(testUser);

      // Second check should detect duplicate phone
      final secondCheck = await storageService.checkForDuplicateUser(
        phoneNumber: testUser.phoneNumber!,
        email: 'different@example.com',
      );
      expect(secondCheck, contains('phone number already exists'));

      // Check should detect duplicate email
      final thirdCheck = await storageService.checkForDuplicateUser(
        phoneNumber: '+2348999888777',
        email: testUser.email!,
      );
      expect(thirdCheck, contains('email address already exists'));
    });
  });
}