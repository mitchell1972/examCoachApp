import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  group('Trial System Tests', () {
    group('UserModel Trial Functionality', () {
      test('should initialize with trial status when user completes signup', () {
        // Given I completed signup
        final signupTime = DateTime.now();
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // When my profile status changes to "trial"
        user.setTrialStatus(signupTime);

        // Then user should have trial status
        expect(user.isOnTrial, isTrue);
        expect(user.trialStartTime, equals(signupTime));
        expect(user.trialExpires, equals(signupTime.add(const Duration(hours: 48))));
      });

      test('should calculate trial expiration as signup time + 48 hours', () {
        // Given a specific signup time
        final signupTime = DateTime(2025, 1, 28, 10, 0, 0);
        final expectedExpiry = DateTime(2025, 1, 30, 10, 0, 0); // 48 hours later
        
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // When trial is set
        user.setTrialStatus(signupTime);

        // Then trial expires exactly 48 hours later
        expect(user.trialExpires, equals(expectedExpiry));
      });

      test('should provide trial remaining time', () {
        // Given a user on trial
        final signupTime = DateTime.now().subtract(const Duration(hours: 24)); // 24 hours ago
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        user.setTrialStatus(signupTime);

        // When checking remaining time
        final remaining = user.trialTimeRemaining;

        // Then should have approximately 24 hours remaining
        expect(remaining?.inHours, equals(23)); // Allow for small time differences
      });

      test('should detect when trial has expired', () {
        // Given a user whose trial started 49 hours ago
        final signupTime = DateTime.now().subtract(const Duration(hours: 49));
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        user.setTrialStatus(signupTime);

        // When checking trial status
        final isExpired = user.isTrialExpired;

        // Then trial should be expired
        expect(isExpired, isTrue);
        expect(user.isOnTrial, isFalse); // Should no longer be on trial
      });

      test('should handle trial status serialization', () {
        // Given a user with trial status (future date)
        final signupTime = DateTime.now().add(const Duration(hours: 1)); // Future date
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        user.setTrialStatus(signupTime);

        // When serializing to JSON
        final json = user.toJson();

        // Then trial data should be included
        expect(json['isOnTrial'], isTrue);
        expect(json['trialStartTime'], isNotNull);
        expect(json['trialExpires'], isNotNull);
      });

      test('should handle trial status deserialization', () {
        // Given JSON with trial data (future date)
        final signupTime = DateTime.now().add(const Duration(hours: 1)); // Future date
        final json = {
          'fullName': 'Test User',
          'phoneNumber': '+1234567890',
          'email': 'test@example.com',
          'currentClass': 'SS3',
          'schoolType': 'Public School',
          'studyFocus': ['Mathematics'],
          'scienceSubjects': ['Physics'],
          'isOnTrial': true,
          'trialStartTime': signupTime.toIso8601String(),
          'trialExpires': signupTime.add(const Duration(hours: 48)).toIso8601String(),
        };

        // When creating user from JSON
        final user = UserModel.fromJson(json);

        // Then trial status should be restored
        expect(user.isOnTrial, isTrue);
        expect(user.trialStartTime, equals(signupTime));
        expect(user.trialExpires, equals(signupTime.add(const Duration(hours: 48))));
      });

      test('should handle users without trial status', () {
        // Given a user without trial status
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // When checking trial status
        // Then should not be on trial
        expect(user.isOnTrial, isFalse);
        expect(user.trialStartTime, isNull);
        expect(user.trialExpires, isNull);
        expect(user.isTrialExpired, isFalse);
        expect(user.trialTimeRemaining, isNull);
      });
    });

    group('Trial Display Formatting', () {
      test('should format trial expiry message correctly', () {
        // Given a user with 25 hours remaining
        final signupTime = DateTime.now().subtract(const Duration(hours: 23));
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        user.setTrialStatus(signupTime);

        // When getting trial display message
        final message = user.trialDisplayMessage;

        // Then should show formatted expiry time
        expect(message, contains('Free trial ends at'));
        expect(message, isNotNull);
      });

      test('should handle expired trial message', () {
        // Given a user with expired trial
        final signupTime = DateTime.now().subtract(const Duration(hours: 50));
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );
        user.setTrialStatus(signupTime);

        // When getting trial display message
        final message = user.trialDisplayMessage;

        // Then should show expired message
        expect(message, contains('Trial expired'));
      });

      test('should handle no trial message', () {
        // Given a user without trial
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // When getting trial display message
        final message = user.trialDisplayMessage;

        // Then should return null or empty
        expect(message, isNull);
      });
    });

    group('Integration Scenarios', () {
      test('Scenario: Trial starts at signup - complete flow', () {
        // Given I completed signup
        final signupTime = DateTime.now();
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // When my profile status changes to "trial"
        user.setTrialStatus(signupTime);

        // Then trialExpires = signupTime + 48 hours
        final expectedExpiry = signupTime.add(const Duration(hours: 48));
        expect(user.trialExpires, equals(expectedExpiry));

        // And the dashboard shows "Free trial ends at [datetime]"
        final displayMessage = user.trialDisplayMessage;
        expect(displayMessage, contains('Free trial ends at'));
        expect(displayMessage, isNotNull);
      });

      test('should maintain backward compatibility with existing users', () {
        // Given an existing user without trial data
        final json = {
          'fullName': 'Test User',
          'phoneNumber': '+1234567890',
          'email': 'test@example.com',
          'currentClass': 'SS3',
          'schoolType': 'Public School',
          'studyFocus': ['Mathematics'],
          'scienceSubjects': ['Physics'],
          'examType': 'WAEC',
          'subject': 'Mathematics',
        };

        // When loading user
        final user = UserModel.fromJson(json);

        // Then should work without trial data
        expect(user.phoneNumber, equals('+1234567890'));
        expect(user.isOnTrial, isFalse);
        expect(user.trialDisplayMessage, isNull);
      });

      test('should handle trial activation during signup flow', () {
        // Given a user going through signup
        final user = UserModel(
          fullName: 'Test User',
          phoneNumber: '+1234567890',
          email: 'test@example.com',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['Mathematics'],
          scienceSubjects: ['Physics'],
        );

        // Initially no trial
        expect(user.isOnTrial, isFalse);

        // When signup completes and trial is activated
        final signupTime = DateTime.now();
        user.setTrialStatus(signupTime);

        // Then trial should be active
        expect(user.isOnTrial, isTrue);
        expect(user.trialStartTime, equals(signupTime));
        expect(user.trialExpires, equals(signupTime.add(const Duration(hours: 48))));
      });
    });
  });
}
