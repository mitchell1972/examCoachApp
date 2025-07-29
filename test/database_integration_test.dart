import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/services/database_service.dart';
import 'package:exam_coach_app/services/supabase_config.dart';

void main() {
  group('Database Integration Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      // Initialize Supabase for testing
      // Note: This requires test environment setup
      try {
        await SupabaseConfig.initialize();
        databaseService = DatabaseService();
      } catch (e) {
        // Skip tests if Supabase is not configured
        print('Skipping database tests - Supabase not configured: $e');
      }
    });

    group('User Management', () {
      testWidgets('should create user with phone authentication', (tester) async {
        // This test requires actual Supabase setup
        // Skip if not configured for testing
        if (!_isSupabaseConfigured()) {
          return;
        }

        final testUser = await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345678',
          fullName: 'Test User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC', 'JAMB'],
          scienceSubjects: ['Physics', 'Chemistry', 'Biology'],
          email: 'test@example.com',
        );

        expect(testUser, isNotNull);
        expect(testUser!.fullName, equals('Test User'));
        expect(testUser.phoneNumber, equals('+2348012345678'));
        expect(testUser.examTypes, contains('WAEC'));
        expect(testUser.examTypes, contains('JAMB'));
        expect(testUser.subjects, contains('Physics'));
        expect(testUser.status, equals('trial'));
        expect(testUser.isTrialActive, isTrue);
      });

      testWidgets('should create user with username and password', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        final testUser = await databaseService.createUserWithPassword(
          username: 'testuser123',
          password: 'SecurePassword123!',
          email: 'testuser@example.com',
          fullName: 'Test User 2',
          phoneNumber: '+2348012345679',
          currentClass: 'SS2',
          schoolType: 'Secondary School',
          studyFocus: ['JAMB'],
          scienceSubjects: ['Mathematics', 'Physics'],
        );

        expect(testUser, isNotNull);
        expect(testUser!.fullName, equals('Test User 2'));
        expect(testUser.phoneNumber, equals('+2348012345679'));
        expect(testUser.examTypes, contains('JAMB'));
        expect(testUser.subjects, contains('Mathematics'));
      });

      testWidgets('should check username availability', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Check for a username that should be available
        final isAvailable = await databaseService.isUsernameAvailable('uniqueusername123');
        expect(isAvailable, isTrue);

        // After creating a user, username should not be available
        await databaseService.createUserWithPassword(
          username: 'takenusername',
          password: 'SecurePassword123!',
          email: 'taken@example.com',
          fullName: 'Taken User',
          phoneNumber: '+2348012345680',
          currentClass: 'SS1',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Biology'],
        );

        final isStillAvailable = await databaseService.isUsernameAvailable('takenusername');
        expect(isStillAvailable, isFalse);
      });

      testWidgets('should retrieve user by phone number', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Create a user first
        await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345681',
          fullName: 'Retrievable User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Chemistry'],
        );

        // Retrieve the user
        final retrievedUser = await databaseService.getUserByPhone('+2348012345681');
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('Retrievable User'));
        expect(retrievedUser.phoneNumber, equals('+2348012345681'));
      });

      testWidgets('should retrieve user by username', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Create a user first
        await databaseService.createUserWithPassword(
          username: 'retrievableuser',
          password: 'SecurePassword123!',
          email: 'retrievable@example.com',
          fullName: 'Retrievable User 2',
          phoneNumber: '+2348012345682',
          currentClass: 'SS2',
          schoolType: 'Secondary School',
          studyFocus: ['JAMB'],
          scienceSubjects: ['Physics'],
        );

        // Retrieve the user
        final retrievedUser = await databaseService.getUserByUsername('retrievableuser');
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.fullName, equals('Retrievable User 2'));
        expect(retrievedUser.phoneNumber, equals('+2348012345682'));
      });
    });

    group('Data Mapping', () {
      testWidgets('should correctly map study focus to exam types', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        final testUser = await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345683',
          fullName: 'Mapping Test User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['Both'], // Should map to both WAEC and JAMB
          scienceSubjects: ['Physics', 'Chemistry'],
        );

        expect(testUser, isNotNull);
        expect(testUser!.examTypes, contains('WAEC'));
        expect(testUser.examTypes, contains('JAMB'));
        expect(testUser.examTypes.length, equals(2));
      });

      testWidgets('should handle single exam type mapping', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        final testUser = await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345684',
          fullName: 'Single Exam User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Biology'],
        );

        expect(testUser, isNotNull);
        expect(testUser!.examTypes, contains('WAEC'));
        expect(testUser.examTypes.length, equals(1));
      });
    });

    group('Trial System Integration', () {
      testWidgets('should initialize trial correctly for new users', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        final testUser = await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345685',
          fullName: 'Trial User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Mathematics'],
        );

        expect(testUser, isNotNull);
        expect(testUser!.status, equals('trial'));
        expect(testUser.trialStartDate, isNotNull);
        expect(testUser.trialExpires, isNotNull);
        expect(testUser.isTrialActive, isTrue);

        // Trial should expire in 48 hours
        final expectedExpiry = testUser.trialStartDate!.add(const Duration(hours: 48));
        final actualExpiry = testUser.trialExpires!;
        final difference = actualExpiry.difference(expectedExpiry).inMinutes.abs();
        expect(difference, lessThan(5)); // Allow 5 minutes tolerance
      });
    });

    group('User Preferences', () {
      testWidgets('should create and update user preferences', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Create a user first
        final testUser = await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345686',
          fullName: 'Preferences User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Physics'],
        );

        expect(testUser, isNotNull);

        // Update preferences
        await databaseService.updateUserPreferences(testUser!.id!, {
          'notifications_enabled': false,
          'theme_preference': 'dark',
          'quiz_difficulty': 'hard',
        });

        // Retrieve preferences
        final preferences = await databaseService.getUserPreferences(testUser.id!);
        expect(preferences, isNotNull);
        expect(preferences!['notifications_enabled'], isFalse);
        expect(preferences['theme_preference'], equals('dark'));
        expect(preferences['quiz_difficulty'], equals('hard'));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle duplicate phone numbers', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Create first user
        await databaseService.createUserWithPhone(
          phoneNumber: '+2348012345687',
          fullName: 'First User',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Physics'],
        );

        // Try to create second user with same phone number
        expect(
          () async => await databaseService.createUserWithPhone(
            phoneNumber: '+2348012345687',
            fullName: 'Second User',
            currentClass: 'SS2',
            schoolType: 'Secondary School',
            studyFocus: ['JAMB'],
            scienceSubjects: ['Chemistry'],
          ),
          throwsException,
        );
      });

      testWidgets('should handle duplicate usernames', (tester) async {
        if (!_isSupabaseConfigured()) {
          return;
        }

        // Create first user
        await databaseService.createUserWithPassword(
          username: 'duplicateuser',
          password: 'SecurePassword123!',
          email: 'first@example.com',
          fullName: 'First User',
          phoneNumber: '+2348012345688',
          currentClass: 'SS3',
          schoolType: 'Secondary School',
          studyFocus: ['WAEC'],
          scienceSubjects: ['Physics'],
        );

        // Try to create second user with same username
        expect(
          () async => await databaseService.createUserWithPassword(
            username: 'duplicateuser',
            password: 'AnotherPassword123!',
            email: 'second@example.com',
            fullName: 'Second User',
            phoneNumber: '+2348012345689',
            currentClass: 'SS2',
            schoolType: 'Secondary School',
            studyFocus: ['JAMB'],
            scienceSubjects: ['Chemistry'],
          ),
          throwsException,
        );
      });
    });
  });
}

bool _isSupabaseConfigured() {
  try {
    // Check if Supabase is properly configured
    // This is a simple check - in real tests you might want more sophisticated checks
    return SupabaseConfig.supabaseUrl != 'https://your-project.supabase.co';
  } catch (e) {
    return false;
  }
}
