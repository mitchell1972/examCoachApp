import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/screens/onboarding_screen.dart';
import 'package:exam_coach_app/screens/registration_screen.dart';
import 'package:exam_coach_app/screens/login_screen.dart';
import 'package:exam_coach_app/services/storage_service.dart';

// Mock MyApp for testing
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Coach',
      home: const OnboardingScreen(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Registration and Login Flow Tests', () {
    late StorageService storageService;

    setUp(() async {
      storageService = StorageService();
      // Clear any existing data before each test
      try {
        await storageService.clearRegistration();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await storageService.clearRegistration();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    testWidgets('Onboarding screen shows registration when no user exists', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should show onboarding screen
      expect(find.text('Exam Coach'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('Can navigate to registration screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap on Create Account button
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Should navigate to registration screen
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('Registration form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const RegistrationScreen(),
      ));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('Phone number validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const RegistrationScreen(),
      ));
      await tester.pumpAndSettle();

      // Enter invalid phone number
      await tester.enterText(find.byKey(const Key('phone_field')), '123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should show phone validation error
      expect(find.textContaining('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('Can fill registration form with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const RegistrationScreen(),
      ));
      await tester.pumpAndSettle();

      // Fill in the form
      await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
      await tester.enterText(find.byKey(const Key('phone_field')), '+2348123456789');
      await tester.enterText(find.byKey(const Key('email_field')), 'john@example.com');
      
      // Select class
      await tester.tap(find.byKey(const Key('class_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SS3').last);
      await tester.pumpAndSettle();

      // Select school type
      await tester.tap(find.byKey(const Key('school_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public School').last);
      await tester.pumpAndSettle();

      // Verify form is filled
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+2348123456789'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('Login screen shows when user is registered', (WidgetTester tester) async {
      // First register a user
      await storageService.saveRegisteredUser({
        'fullName': 'Test User',
        'phoneNumber': '+2348123456789',
        'email': 'test@example.com',
        'currentClass': 'SS3',
        'schoolType': 'Public School',
        'studyFocus': ['Mathematics', 'Physics'],
        'scienceSubjects': ['Physics', 'Chemistry'],
        'registrationDate': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should show login option as primary
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Create New Account'), findsOneWidget);
    });

    testWidgets('Can navigate to login screen when user exists', (WidgetTester tester) async {
      // Register a user first
      await storageService.saveRegisteredUser({
        'fullName': 'Test User',
        'phoneNumber': '+2348123456789',
        'email': 'test@example.com',
        'currentClass': 'SS3',
        'schoolType': 'Public School',
        'studyFocus': ['Mathematics'],
        'scienceSubjects': ['Physics'],
        'registrationDate': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap on Login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.textContaining('Send OTP to'), findsOneWidget);
    });

    testWidgets('Login screen shows no user found when no registration', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
      ));
      await tester.pumpAndSettle();

      // Should show no user found message
      expect(find.text('No Account Found'), findsOneWidget);
      expect(find.text('You need to create an account first before you can login.'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Can navigate to forgot phone screen', (WidgetTester tester) async {
      // Register a user first
      await storageService.saveRegisteredUser({
        'fullName': 'Test User',
        'phoneNumber': '+2348123456789',
        'email': 'test@example.com',
        'currentClass': 'SS3',
        'schoolType': 'Public School',
        'studyFocus': ['Mathematics'],
        'scienceSubjects': ['Physics'],
        'registrationDate': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap on forgot phone number
      await tester.tap(find.text('Forgot phone number?'));
      await tester.pumpAndSettle();

      // Should navigate to forgot phone screen
      expect(find.text('Forgot Your Phone Number?'), findsOneWidget);
      expect(find.text('Clear Data & Register New Number'), findsOneWidget);
    });

    testWidgets('Storage service works correctly', (WidgetTester tester) async {
      // Test saving user data
      final userData = {
        'fullName': 'Test User',
        'phoneNumber': '+2348123456789',
        'email': 'test@example.com',
        'currentClass': 'SS3',
        'schoolType': 'Public School',
        'studyFocus': ['Mathematics', 'Physics'],
        'scienceSubjects': ['Physics', 'Chemistry'],
        'registrationDate': DateTime.now().toIso8601String(),
      };

      await storageService.saveRegisteredUser(userData);

      // Verify user is registered
      final isRegistered = await storageService.isUserRegistered();
      expect(isRegistered, true);

      // Verify user data can be retrieved
      final retrievedUser = await storageService.getRegisteredUser();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.fullName, 'Test User');
      expect(retrievedUser.phoneNumber, '+2348123456789');
      expect(retrievedUser.studyFocus.length, 2);

      // Test clearing registration
      await storageService.clearRegistration();
      final isRegisteredAfterClear = await storageService.isUserRegistered();
      expect(isRegisteredAfterClear, false);
    });

    testWidgets('Multi-selection widgets work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const RegistrationScreen(),
      ));
      await tester.pumpAndSettle();

      // Navigate to study focus step
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('phone_field')), '+2348123456789');
      
      // Select class and school type
      await tester.tap(find.byKey(const Key('class_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SS3').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('school_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public School').last);
      await tester.pumpAndSettle();

      // Continue to next step
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should be on study focus selection
      expect(find.text('What would you like to focus on?'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });
}
