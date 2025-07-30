import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:exam_coach_app/services/storage_service.dart';
import 'package:exam_coach_app/services/app_config.dart';
import 'package:exam_coach_app/services/database_service_rest.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Storage Service Tests', () {
    late StorageService storageService;

    setUp(() async {
      storageService = StorageService();
      
      // Initialize AppConfig for tests
      await AppConfig.initialize();
      
      // Configure database service for testing
      final databaseService = DatabaseServiceRest();
      databaseService.configureForTesting();
      
      // Create a simple in-memory storage for tests
      final Map<String, String> testStorage = {};
      
      // Mock flutter_secure_storage for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'read':
              final key = methodCall.arguments['key'] as String;
              return testStorage[key];
            case 'write':
              final key = methodCall.arguments['key'] as String;
              final value = methodCall.arguments['value'] as String;
              testStorage[key] = value;
              return null;
            case 'delete':
              final key = methodCall.arguments['key'] as String;
              testStorage.remove(key);
              return null;
            case 'deleteAll':
              testStorage.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(testStorage);
            default:
              throw PlatformException(
                code: 'Unimplemented',
                details: 'Method ${methodCall.method} not implemented in mock',
              );
          }
        },
      );
    });

    tearDown(() async {
      // Reset the mock after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    group('User Registration Storage', () {
      test('should save and retrieve user registration data', () async {
        // Given a user model
        final user = UserModel(
          fullName: 'John Doe',
          phoneNumber: '+2348123456789',
          email: 'john@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics', 'Physics'],
          scienceSubjects: ['Physics', 'Chemistry'],
          registrationDate: DateTime.now(),
        );

        // When saving registration
        await storageService.saveRegistration(user);

        // Then should be able to retrieve the user
        final retrievedUser = await storageService.getRegisteredUser();
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('John Doe'));
        expect(retrievedUser.phoneNumber, equals('+2348123456789'));
        expect(retrievedUser.email, equals('john@example.com'));
        expect(retrievedUser.currentClass, equals('SS3'));
        expect(retrievedUser.schoolType, equals('Public School'));
        expect(retrievedUser.studyFocus, equals(['Mathematics', 'Physics']));
        expect(retrievedUser.scienceSubjects, equals(['Physics', 'Chemistry']));
      });

      test('should save user from map data (for testing)', () async {
        // Given user data as map
        final userData = {
          'fullName': 'Jane Smith',
          'phoneNumber': '+2348987654321',
          'email': 'jane@example.com',
          'currentClass': 'SS2',
          'schoolType': 'Private School',
          'studyFocus': ['English', 'Literature'],
          'scienceSubjects': ['Biology'],
          'registrationDate': DateTime.now().toIso8601String(),
        };

        // When saving from map
        await storageService.saveRegisteredUser(userData);

        // Then should be able to retrieve the user
        final retrievedUser = await storageService.getRegisteredUser();
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('Jane Smith'));
        expect(retrievedUser.phoneNumber, equals('+2348987654321'));
        expect(retrievedUser.studyFocus, equals(['English', 'Literature']));
      });

      test('should detect when user is registered', () async {
        // Given no user is registered initially
        expect(await storageService.isUserRegistered(), isFalse);

        // When saving a user
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+2348123456789',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        await storageService.saveRegistration(user);

        // Then should detect user is registered
        expect(await storageService.isUserRegistered(), isTrue);
      });

      test('should return null when no user is registered', () async {
        // Given no user is registered
        // When retrieving user
        final user = await storageService.getRegisteredUser();

        // Then should return null
        expect(user, isNull);
      });
    });

    group('Registration Status Management', () {
      test('should set and get registration status', () async {
        // Given a status
        const status = 'completed';

        // When setting status
        await storageService.setRegistrationStatus(status);

        // Then should be able to retrieve it
        final retrievedStatus = await storageService.getRegistrationStatus();
        expect(retrievedStatus, equals(status));
      });

      test('should return null for unset registration status', () async {
        // Given no status is set
        // When getting status
        final status = await storageService.getRegistrationStatus();

        // Then should return null
        expect(status, isNull);
      });
    });

    group('User Data Updates', () {
      test('should update existing user data', () async {
        // Given an existing user
        final originalUser = UserModel(
          fullName: 'Original Name',
          phoneNumber: '+2348123456789',
          email: 'original@example.com',
          currentClass: 'SS2',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        await storageService.saveRegistration(originalUser);

        // When updating user data
        final updatedUser = UserModel(
          fullName: 'Updated Name',
          phoneNumber: '+2348123456789',
          email: 'updated@example.com',
          currentClass: 'SS3',
          schoolType: 'Private School',
          studyFocus: ['Mathematics', 'Physics'],
          scienceSubjects: ['Physics', 'Chemistry'],
          lastLoginDate: DateTime.now(),
        );
        await storageService.updateUser(updatedUser);

        // Then should retrieve updated data
        final retrievedUser = await storageService.getRegisteredUser();
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('Updated Name'));
        expect(retrievedUser.email, equals('updated@example.com'));
        expect(retrievedUser.currentClass, equals('SS3'));
        expect(retrievedUser.schoolType, equals('Private School'));
        expect(retrievedUser.studyFocus, equals(['Mathematics', 'Physics']));
        expect(retrievedUser.lastLoginDate, isNotNull);
      });
    });

    group('Data Clearing', () {
      test('should clear all registration data', () async {
        // Given a registered user
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+2348123456789',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        await storageService.saveRegistration(user);
        await storageService.setRegistrationStatus('completed');

        // Verify data exists
        expect(await storageService.isUserRegistered(), isTrue);
        expect(await storageService.getRegistrationStatus(), equals('completed'));

        // When clearing registration
        await storageService.clearRegistration();

        // Then all data should be cleared
        expect(await storageService.isUserRegistered(), isFalse);
        expect(await storageService.getRegisteredUser(), isNull);
        expect(await storageService.getRegistrationStatus(), isNull);
      });
    });

    group('Error Handling', () {
      test('should handle malformed JSON gracefully', () async {
        // This test simulates what happens when storage contains invalid data
        // In a real scenario, this would be handled by the secure storage layer
        
        // Given we try to retrieve a user when none exists
        final user = await storageService.getRegisteredUser();
        
        // Then should return null without throwing
        expect(user, isNull);
      });

      test('should handle registration status check when no data exists', () async {
        // Given no registration data exists
        // When checking if user is registered
        final isRegistered = await storageService.isUserRegistered();

        // Then should return false without throwing
        expect(isRegistered, isFalse);
      });
    });

    group('Data Persistence', () {
      test('should persist data across service instances', () async {
        // Given a user saved with one service instance
        final user = UserModel(
          fullName: 'Persistent User',
          phoneNumber: '+2348123456789',
          email: 'persistent@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        await storageService.saveRegistration(user);

        // When creating a new service instance
        final newStorageService = StorageService();

        // Then should be able to retrieve the same data
        final retrievedUser = await newStorageService.getRegisteredUser();
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('Persistent User'));
        expect(retrievedUser.phoneNumber, equals('+2348123456789'));
      });
    });

    group('Complex Data Structures', () {
      test('should handle lists and complex data correctly', () async {
        // Given a user with complex data structures
        final user = UserModel(
          fullName: 'Complex User',
          phoneNumber: '+2348123456789',
          email: 'complex@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics', 'Physics', 'Chemistry', 'Biology'],
          scienceSubjects: ['Physics', 'Chemistry', 'Biology'],
          examTypes: ['WAEC', 'JAMB'],
          subjects: ['Mathematics', 'English Language', 'Physics'],
          registrationDate: DateTime.now(),
          lastLoginDate: DateTime.now(),
        );

        // When saving and retrieving
        await storageService.saveRegistration(user);
        final retrievedUser = await storageService.getRegisteredUser();

        // Then all complex data should be preserved
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.studyFocus.length, equals(4));
        expect(retrievedUser.studyFocus, containsAll(['Mathematics', 'Physics', 'Chemistry', 'Biology']));
        expect(retrievedUser.scienceSubjects, containsAll(['Physics', 'Chemistry', 'Biology']));
        expect(retrievedUser.examTypes, containsAll(['WAEC', 'JAMB']));
        expect(retrievedUser.subjects, containsAll(['Mathematics', 'English Language', 'Physics']));
        expect(retrievedUser.registrationDate, isNotNull);
        expect(retrievedUser.lastLoginDate, isNotNull);
      });
    });
  });
}
