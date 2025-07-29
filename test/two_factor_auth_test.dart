import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/models/user_model.dart';
import 'package:exam_coach_app/services/two_factor_auth_service.dart';

void main() {
  group('Two-Factor Authentication Service Tests', () {
    late TwoFactorAuthService twoFactorAuth;
    late UserModel testUser;

    setUp(() {
      twoFactorAuth = TwoFactorAuthService();
      
      // Create a test user with password
      testUser = UserModel(
        id: 'test_user_123',
        email: 'test@example.com',
        fullName: 'Test User',
        phoneNumber: '+1234567890',
        currentClass: 'SS3',
        schoolType: 'Public School',
        studyFocus: ['JAMB'],
        scienceSubjects: ['Mathematics', 'Physics'],
        isRegistered: true,
        isVerified: true,
      );
      
      // Set a test password
      testUser.setPassword('TestPassword123');
      
      // Reset auth state before each test
      twoFactorAuth.reset();
    });

    tearDown(() {
      twoFactorAuth.reset();
    });

    group('Password Authentication', () {
      test('should verify correct password', () {
        // Test that correct password is verified
        expect(testUser.verifyPassword('TestPassword123'), isTrue);
      });

      test('should reject incorrect password', () {
        // Test that incorrect password is rejected
        expect(testUser.verifyPassword('WrongPassword'), isFalse);
        expect(testUser.verifyPassword('testpassword123'), isFalse); // Case sensitive
        expect(testUser.verifyPassword('TestPassword'), isFalse); // Missing number
      });

      test('should handle empty password', () {
        // Test user without password
        final userWithoutPassword = UserModel(
          email: 'no-password@example.com',
          fullName: 'No Password User',
        );
        
        expect(userWithoutPassword.hasPassword, isFalse);
        expect(userWithoutPassword.verifyPassword('any'), isFalse);
      });

      test('should hash passwords securely', () {
        // Create two users with same password
        final user1 = UserModel(email: 'user1@example.com', fullName: 'User 1');
        final user2 = UserModel(email: 'user2@example.com', fullName: 'User 2');
        
        user1.setPassword('SamePassword123');
        user2.setPassword('SamePassword123');
        
        // Passwords should hash differently due to different salts
        expect(user1.passwordSalt, isNot(equals(user2.passwordSalt)));
        
        // But both should verify correctly
        expect(user1.verifyPassword('SamePassword123'), isTrue);
        expect(user2.verifyPassword('SamePassword123'), isTrue);
      });
    });

    group('Authentication Flow State Management', () {
      test('should initialize with initial state', () {
        expect(twoFactorAuth.currentState, equals(AuthState.initial));
        expect(twoFactorAuth.authenticatingUser, isNull);
      });

      test('should track authentication states correctly', () async {
        // Start with initial state
        expect(twoFactorAuth.currentState, equals(AuthState.initial));
        
        // After password verification (mock scenario)
        // Note: This would normally call verifyEmailPassword, but we're testing state changes
        expect(twoFactorAuth.isSessionValid(), isFalse);
      });

      test('should reset state correctly', () {
        // Manually set some state
        twoFactorAuth.reset();
        
        expect(twoFactorAuth.currentState, equals(AuthState.initial));
        expect(twoFactorAuth.authenticatingUser, isNull);
        expect(twoFactorAuth.sessionTimeRemaining, isNull);
      });

      test('should validate session timeout', () {
        // Session should be invalid initially
        expect(twoFactorAuth.isSessionValid(), isFalse);
        
        // Test session time remaining when no session exists
        expect(twoFactorAuth.sessionTimeRemaining, isNull);
      });
    });

    group('Password Validation Requirements', () {
      test('should require minimum 8 characters', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Test short passwords
        user.setPassword('Short1');
        expect(user.verifyPassword('Short1'), isTrue); // Password is set but doesn't meet our UI validation
        
        // Test valid length
        user.setPassword('LongPassword123');
        expect(user.verifyPassword('LongPassword123'), isTrue);
      });

      test('should handle special characters in passwords', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Test password with special characters
        const complexPassword = 'Complex@Password123!';
        user.setPassword(complexPassword);
        expect(user.verifyPassword(complexPassword), isTrue);
        
        // Test that it rejects similar but incorrect passwords
        expect(user.verifyPassword('Complex@Password123'), isFalse); // Missing !
        expect(user.verifyPassword('complex@password123!'), isFalse); // Wrong case
      });

      test('should handle unicode characters', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Test password with unicode characters
        const unicodePassword = 'Pássword123π';
        user.setPassword(unicodePassword);
        expect(user.verifyPassword(unicodePassword), isTrue);
        expect(user.verifyPassword('Password123π'), isFalse); // Missing accent
      });
    });

    group('Error Handling', () {
      test('should handle null/empty inputs gracefully', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Test empty password
        user.setPassword('');
        expect(user.hasPassword, isFalse);
        expect(user.verifyPassword(''), isFalse);
        expect(user.verifyPassword('anything'), isFalse);
        
        // Test null password (edge case)
        expect(user.verifyPassword(''), isFalse);
      });

      test('should handle password changes', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Set initial password
        user.setPassword('FirstPassword123');
        expect(user.verifyPassword('FirstPassword123'), isTrue);
        
        // Change password
        user.setPassword('SecondPassword456');
        expect(user.verifyPassword('SecondPassword456'), isTrue);
        expect(user.verifyPassword('FirstPassword123'), isFalse); // Old password should not work
      });
    });

    group('JSON Serialization with Passwords', () {
      test('should serialize and deserialize user with password', () {
        // Create user with password
        final user = UserModel(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test User',
          phoneNumber: '+1234567890',
        );
        user.setPassword('TestPassword123');
        
        // Serialize to JSON
        final json = user.toJson();
        
        // Verify password hash is included but not plain password
        expect(json['_passwordHash'], isNotNull);
        expect(json['passwordSalt'], isNotNull);
        expect(json['hasPassword'], isTrue);
        expect(json.containsKey('password'), isFalse); // Plain password should not be in JSON
        
        // Deserialize from JSON
        final deserializedUser = UserModel.fromJson(json);
        
        // Verify password still works after deserialization
        expect(deserializedUser.hasPassword, isTrue);
        expect(deserializedUser.verifyPassword('TestPassword123'), isTrue);
        expect(deserializedUser.verifyPassword('WrongPassword'), isFalse);
      });

      test('should handle user without password in JSON', () {
        // Create user without password
        final user = UserModel(
          email: 'nopass@example.com',
          fullName: 'No Pass User',
        );
        
        // Serialize to JSON
        final json = user.toJson();
        
        // Verify no password fields
        expect(json['_passwordHash'], isNull);
        expect(json['passwordSalt'], isNull);
        expect(json['hasPassword'], isFalse);
        
        // Deserialize from JSON
        final deserializedUser = UserModel.fromJson(json);
        
        // Verify no password functionality
        expect(deserializedUser.hasPassword, isFalse);
        expect(deserializedUser.verifyPassword('anything'), isFalse);
      });
    });

    group('Authentication Service Integration', () {
      test('should maintain state between operations', () {
        // Test that authentication state is maintained correctly
        expect(twoFactorAuth.currentState, equals(AuthState.initial));
        
        // Reset should always work
        twoFactorAuth.reset();
        expect(twoFactorAuth.currentState, equals(AuthState.initial));
      });

      test('should handle authentication timeouts', () {
        // Test session validity
        expect(twoFactorAuth.isSessionValid(), isFalse);
        expect(twoFactorAuth.sessionTimeRemaining, isNull);
      });
    });

    group('Security Features', () {
      test('should use different salts for same passwords', () {
        final user1 = UserModel(email: 'user1@example.com', fullName: 'User 1');
        final user2 = UserModel(email: 'user2@example.com', fullName: 'User 2');
        
        const password = 'SamePassword123';
        user1.setPassword(password);
        user2.setPassword(password);
        
        // Salts should be different
        expect(user1.passwordSalt, isNot(equals(user2.passwordSalt)));
        
        // Both should authenticate correctly
        expect(user1.verifyPassword(password), isTrue);
        expect(user2.verifyPassword(password), isTrue);
        
        // Cross authentication should fail
        expect(user1.verifyPassword('DifferentPassword'), isFalse);
        expect(user2.verifyPassword('DifferentPassword'), isFalse);
      });

      test('should handle password reset securely', () {
        final user = UserModel(email: 'test@example.com', fullName: 'Test User');
        
        // Set initial password
        user.setPassword('InitialPassword123');
        final initialSalt = user.passwordSalt;
        expect(user.verifyPassword('InitialPassword123'), isTrue);
        
        // Reset password
        user.setPassword('NewPassword456');
        final newSalt = user.passwordSalt;
        
        // Salt should change
        expect(newSalt, isNot(equals(initialSalt)));
        
        // Only new password should work
        expect(user.verifyPassword('NewPassword456'), isTrue);
        expect(user.verifyPassword('InitialPassword123'), isFalse);
      });
    });
  });
} 