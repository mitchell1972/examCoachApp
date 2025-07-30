import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/services/storage_service.dart';
import 'package:exam_coach_app/services/database_service_rest.dart';
import 'package:exam_coach_app/services/app_config.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Duplicate Phone Number Validation Tests', () {
    late StorageService storageService;
    late DatabaseServiceRest databaseService;

    setUp(() async {
      // Initialize app configuration for tests
      await AppConfig.initialize();
      
      // Configure database service for testing
      databaseService = DatabaseServiceRest();
      databaseService.configureForTesting();
      
      storageService = StorageService();
    });

    tearDown(() async {
      // Clean up mock data after each test (avoid secure storage in tests)
      try {
        databaseService.clearMockData();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    test('Should prevent registration of duplicate phone number', () async {
      const duplicatePhone = '+2348123456789';
      
      // Create first user and add to mock database
      final firstUser = UserModel(
        id: 'user_1',
        fullName: 'First User',
        phoneNumber: duplicatePhone,
        email: 'first@example.com',
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'active',
        createdAt: DateTime.now(),
      );
      
      // Add first user to mock database
      databaseService.addMockUser(firstUser);
      
      // Attempt to register second user with same phone number
      final secondUser = UserModel(
        id: 'user_2',
        fullName: 'Second User',
        phoneNumber: duplicatePhone, // Same phone number!
        email: 'second@example.com',
        currentClass: 'SS2',
        schoolType: 'Secondary',
        studyFocus: ['JAMB'],
        scienceSubjects: ['Chemistry'],
        status: 'trial',
        createdAt: DateTime.now(),
      );

      // Check for duplicate - should detect the existing phone number
      final duplicateError = await storageService.checkForDuplicateUser(
        phoneNumber: duplicatePhone,
        email: 'second@example.com',
      );

      // Should return error message about duplicate phone number
      expect(duplicateError, isNotNull);
      expect(duplicateError, contains('phone number already exists'));
      expect(duplicateError, contains('try logging in instead'));
    });

    test('Should prevent registration via saveRegistration method', () async {
      const duplicatePhone = '+2348987654321';
      
      // Create and save first user
      final firstUser = UserModel(
        id: 'user_1',
        fullName: 'First User',
        phoneNumber: duplicatePhone,
        email: 'first@example.com',
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'active',
        createdAt: DateTime.now(),
      );
      
      // Add first user to mock database
      databaseService.addMockUser(firstUser);
      
      // Attempt to register second user with same phone number
      final secondUser = UserModel(
        id: 'user_2',
        fullName: 'Second User',
        phoneNumber: duplicatePhone, // Same phone number!
        email: 'different@example.com',
        currentClass: 'SS1',
        schoolType: 'Secondary',
        studyFocus: ['JAMB'],
        scienceSubjects: ['Biology'],
        status: 'trial',
        createdAt: DateTime.now(),
      );

      // Attempt to save registration - should throw exception
      expect(
        () async => await storageService.saveRegistration(secondUser),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('phone number already exists'),
        )),
      );
    });

    test('Should allow validation of unique phone number', () async {
      const uniquePhone = '+2348555666777';
      
      // Check for duplicate - should return null (no duplicates)
      final duplicateError = await storageService.checkForDuplicateUser(
        phoneNumber: uniquePhone,
        email: 'unique@example.com',
      );

      // Should NOT return any error - validation passes
      expect(duplicateError, isNull);
      
      // Verify this phone number is indeed unique in our mock database
      final existingUser = await databaseService.getUserByPhone(uniquePhone);
      expect(existingUser, isNull);
      
      // Verify email is also unique
      final existingEmail = await databaseService.getUserByEmail('unique@example.com');
      expect(existingEmail, isNull);
    });

    test('Should detect duplicate email addresses', () async {
      const duplicateEmail = 'duplicate@example.com';
      
      // Create first user and add to mock database
      final firstUser = UserModel(
        id: 'user_1',
        fullName: 'First User',
        phoneNumber: '+2348111111111',
        email: duplicateEmail,
        currentClass: 'SS3',
        schoolType: 'Secondary',
        studyFocus: ['WAEC'],
        scienceSubjects: ['Physics'],
        status: 'active',
        createdAt: DateTime.now(),
      );
      
      // Add first user to mock database
      databaseService.addMockUser(firstUser);
      
      // Check for duplicate with different phone but same email
      final duplicateError = await storageService.checkForDuplicateUser(
        phoneNumber: '+2348222222222', // Different phone
        email: duplicateEmail, // Same email!
      );

      // Should return error message about duplicate email
      expect(duplicateError, isNotNull);
      expect(duplicateError, contains('email address already exists'));
      expect(duplicateError, contains('try logging in instead'));
    });

    test('Should require phone number', () async {
      // Check for duplicate with empty phone number
      final duplicateError = await storageService.checkForDuplicateUser(
        phoneNumber: '', // Empty phone number
        email: 'test@example.com',
      );

      // Should return error about required phone number
      expect(duplicateError, isNotNull);
      expect(duplicateError, 'Phone number is required');
    });
  });
}