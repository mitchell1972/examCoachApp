import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/screens/registration_screen.dart';
import 'package:exam_coach_app/screens/login_screen.dart';
import 'package:exam_coach_app/services/storage_service.dart';
import 'package:exam_coach_app/services/two_factor_auth_service.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Updated Registration and Authentication Flow Tests', () {
    late StorageService storageService;
    late TwoFactorAuthService twoFactorAuth;

    setUp(() async {
      storageService = StorageService();
      twoFactorAuth = TwoFactorAuthService();
      
      // Clear any existing data before each test
      try {
        await storageService.clearRegistration();
        twoFactorAuth.reset();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await storageService.clearRegistration();
        twoFactorAuth.reset();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('Registration with Password', () {
      testWidgets('Registration form includes password fields', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const RegistrationScreen(),
        ));
        await tester.pumpAndSettle();

        // Check that password fields are present
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);
        
        // Check that email is now required
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.textContaining('Optional'), findsNothing); // Email should no longer be optional
      });

      testWidgets('Password validation works correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const RegistrationScreen(),
        ));
        await tester.pumpAndSettle();

        // Fill in basic info with valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name').first,
          'John Doe'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number').first,
          '+2348123456789'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address').first,
          'john@example.com'
        );

        // Test weak password validation
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password').first,
          'weak'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password').first,
          'weak'
        );

        // Try to proceed (should trigger validation)
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should show password validation errors
        expect(find.textContaining('Password must be at least 8 characters'), findsOneWidget);
      });

      testWidgets('Password confirmation validation works', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const RegistrationScreen(),
        ));
        await tester.pumpAndSettle();

        // Fill in basic info
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name').first,
          'John Doe'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number').first,
          '+2348123456789'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address').first,
          'john@example.com'
        );

        // Test mismatched passwords
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password').first,
          'StrongPassword123'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password').first,
          'DifferentPassword123'
        );

        // Try to proceed
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should show password mismatch error
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('Successful registration with valid password', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const RegistrationScreen(),
        ));
        await tester.pumpAndSettle();

        // Fill in basic info with valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name').first,
          'Jane Smith'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number').first,
          '+2348123456789'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address').first,
          'jane@example.com'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password').first,
          'SecurePassword123'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password').first,
          'SecurePassword123'
        );

        // Proceed to next step
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should move to academic profile step
        expect(find.text('Academic Profile'), findsOneWidget);
      });
    });

    group('Two-Factor Authentication Flow', () {
      testWidgets('Login screen shows email/password form initially', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const LoginScreen(),
        ));
        await tester.pumpAndSettle();

        // Should show new login form
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        
        // Should not show old OTP form initially
        expect(find.text('Send OTP'), findsNothing);
      });

      testWidgets('Email/password validation works on login', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const LoginScreen(),
        ));
        await tester.pumpAndSettle();

        // Try to login without filling fields
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('Invalid email format shows validation error', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const LoginScreen(),
        ));
        await tester.pumpAndSettle();

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address').first,
          'invalid-email'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password').first,
          'somepassword'
        );

        // Try to login
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should show email validation error
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('Password visibility toggle works', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: const LoginScreen(),
        ));
        await tester.pumpAndSettle();

        // Find password field and visibility icons
        final passwordField = find.widgetWithText(TextFormField, 'Password').first;
        expect(passwordField, findsOneWidget);

        // Check that visibility off icon is present initially (password obscured)
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);

        // Tap visibility icon to show password
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        // Check that visibility icon changed to show password is visible
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        // Tap again to hide password
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        // Should show visibility off icon again
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });
    });

    group('Password Security in UserModel', () {
      test('User password is hashed and salted correctly', () {
        final user = UserModel(
          email: 'test@example.com',
          fullName: 'Test User',
        );

        // Set password
        user.setPassword('MySecurePassword123');

        // Check that password is hashed
        expect(user.hasPassword, isTrue);
        expect(user.passwordSalt, isNotNull);
        expect(user.passwordSalt!.isNotEmpty, isTrue);

        // Verify password works
        expect(user.verifyPassword('MySecurePassword123'), isTrue);
        expect(user.verifyPassword('WrongPassword'), isFalse);
      });

      test('Password serialization does not expose plain text', () {
        final user = UserModel(
          email: 'test@example.com',
          fullName: 'Test User',
        );

        user.setPassword('SuperSecret123');

        // Serialize to JSON
        final json = user.toJson();

        // Check that plain password is not in JSON
        expect(json.toString().contains('SuperSecret123'), isFalse);
        expect(json['_passwordHash'], isNotNull);
        expect(json['passwordSalt'], isNotNull);
        expect(json['hasPassword'], isTrue);

        // Deserialize and verify password still works
        final deserializedUser = UserModel.fromJson(json);
        expect(deserializedUser.verifyPassword('SuperSecret123'), isTrue);
        expect(deserializedUser.verifyPassword('WrongPassword'), isFalse);
      });

      test('Users with same password have different salts', () {
        final user1 = UserModel(email: 'user1@example.com', fullName: 'User 1');
        final user2 = UserModel(email: 'user2@example.com', fullName: 'User 2');

        const password = 'SamePassword123';
        user1.setPassword(password);
        user2.setPassword(password);

        // Should have different salts
        expect(user1.passwordSalt, isNot(equals(user2.passwordSalt)));

        // But both should verify correctly
        expect(user1.verifyPassword(password), isTrue);
        expect(user2.verifyPassword(password), isTrue);
      });
    });

    group('Backward Compatibility', () {
      test('Existing users without passwords are handled gracefully', () {
        // Create user as if from old registration (no password)
        final oldUser = UserModel(
          email: 'old@example.com',
          fullName: 'Old User',
          phoneNumber: '+2348123456789',
        );

        // Should indicate no password
        expect(oldUser.hasPassword, isFalse);
        expect(oldUser.verifyPassword('anything'), isFalse);

        // Should be able to add password later
        oldUser.setPassword('NewPassword123');
        expect(oldUser.hasPassword, isTrue);
        expect(oldUser.verifyPassword('NewPassword123'), isTrue);
      });

      test('JSON deserialization handles missing password fields', () {
        // Simulate old user data without password fields
        final oldJsonData = {
          'id': 'old_user_123',
          'email': 'old@example.com',
          'fullName': 'Old User',
          'phoneNumber': '+2348123456789',
          'isRegistered': true,
          // No password fields
        };

        final user = UserModel.fromJson(oldJsonData);

        expect(user.hasPassword, isFalse);
        expect(user.verifyPassword('anything'), isFalse);
        expect(user.email, equals('old@example.com'));
        expect(user.fullName, equals('Old User'));
      });
    });

    group('Two-Factor Auth Service States', () {
      test('Authentication state transitions correctly', () {
        final auth = TwoFactorAuthService();

        // Initial state
        expect(auth.currentState, equals(AuthState.initial));
        expect(auth.authenticatingUser, isNull);
        expect(auth.isSessionValid(), isFalse);

        // Reset should maintain initial state
        auth.reset();
        expect(auth.currentState, equals(AuthState.initial));
        expect(auth.authenticatingUser, isNull);
      });

      test('Session timeout is handled correctly', () {
        final auth = TwoFactorAuthService();

        // No session initially
        expect(auth.sessionTimeRemaining, isNull);
        expect(auth.isSessionValid(), isFalse);

        // After reset, still no session
        auth.reset();
        expect(auth.sessionTimeRemaining, isNull);
        expect(auth.isSessionValid(), isFalse);
      });
    });
  });
} 