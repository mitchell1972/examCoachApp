import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/screens/registration_screen.dart';

void main() {
  group('Registration Step Validation Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = MaterialApp(
        home: const RegistrationScreen(),
      );
    });

    group('Password Confirmation Validation', () {
      testWidgets('should prevent navigation when passwords do not match', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Fill in the basic information form with mismatched passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe'); // Full name
        await tester.enterText(find.byType(TextFormField).at(1), '+2348012345678'); // Phone
        await tester.enterText(find.byType(TextFormField).at(2), 'john@example.com'); // Email
        await tester.enterText(find.byType(TextFormField).at(3), 'Password123!'); // Password
        await tester.enterText(find.byType(TextFormField).at(4), 'DifferentPassword123!'); // Confirm Password (different)
        
        await tester.pumpAndSettle();
        
        // Try to move to next step
        final nextButton = find.text('Next');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should still be on step 0 (Basic Information) due to password mismatch
        expect(find.text('Basic Information'), findsOneWidget);
        
        // Should show password confirmation error
        expect(find.textContaining('Password Confirmation Error'), findsOneWidget);
        expect(find.textContaining('Passwords do not match'), findsOneWidget);
      });

      testWidgets('should allow navigation when passwords match', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Fill in the basic information form with matching passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe'); // Full name
        await tester.enterText(find.byType(TextFormField).at(1), '+2348012345678'); // Phone
        await tester.enterText(find.byType(TextFormField).at(2), 'john@example.com'); // Email
        await tester.enterText(find.byType(TextFormField).at(3), 'Password123!'); // Password
        await tester.enterText(find.byType(TextFormField).at(4), 'Password123!'); // Confirm Password (matching)
        
        await tester.pumpAndSettle();
        
        // Try to move to next step
        final nextButton = find.text('Next');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should move to step 1 (Academic Profile)
        expect(find.text('Academic Profile'), findsOneWidget);
        expect(find.text('Basic Information'), findsNothing);
      });

      testWidgets('should prevent navigation when password is too weak', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Fill in the basic information form with weak password
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe'); // Full name
        await tester.enterText(find.byType(TextFormField).at(1), '+2348012345678'); // Phone
        await tester.enterText(find.byType(TextFormField).at(2), 'john@example.com'); // Email
        await tester.enterText(find.byType(TextFormField).at(3), 'weak'); // Password (too weak)
        await tester.enterText(find.byType(TextFormField).at(4), 'weak'); // Confirm Password (matching but weak)
        
        await tester.pumpAndSettle();
        
        // Try to move to next step
        final nextButton = find.text('Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should still be on step 0 due to weak password
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.textContaining('Password Error'), findsOneWidget);
      });
    });

    group('Step Navigation Validation', () {
      testWidgets('should prevent navigation when required fields are empty', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Try to move to next step without filling any fields
        final nextButton = find.text('Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should still be on step 0
        expect(find.text('Basic Information'), findsOneWidget);
        
        // Should show validation error for required fields
        expect(find.textContaining('Error'), findsOneWidget);
      });

      testWidgets('should prevent navigation when email format is invalid', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Fill in form with invalid email
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe'); // Full name
        await tester.enterText(find.byType(TextFormField).at(1), '+2348012345678'); // Phone
        await tester.enterText(find.byType(TextFormField).at(2), 'invalid-email'); // Invalid email
        await tester.enterText(find.byType(TextFormField).at(3), 'Password123!'); // Password
        await tester.enterText(find.byType(TextFormField).at(4), 'Password123!'); // Confirm Password
        
        await tester.pumpAndSettle();
        
        // Try to move to next step
        final nextButton = find.text('Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should still be on step 0 due to invalid email
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.textContaining('Email Error'), findsOneWidget);
      });

      testWidgets('should prevent navigation when phone number format is invalid', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Fill in form with invalid phone number
        await tester.enterText(find.byType(TextFormField).at(0), 'John Doe'); // Full name
        await tester.enterText(find.byType(TextFormField).at(1), '12345'); // Invalid phone (no country code, too short)
        await tester.enterText(find.byType(TextFormField).at(2), 'john@example.com'); // Email
        await tester.enterText(find.byType(TextFormField).at(3), 'Password123!'); // Password
        await tester.enterText(find.byType(TextFormField).at(4), 'Password123!'); // Confirm Password
        
        await tester.pumpAndSettle();
        
        // Try to move to next step
        final nextButton = find.text('Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        // Should still be on step 0 due to invalid phone
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.textContaining('Phone Number Error'), findsOneWidget);
      });
    });

    group('Academic Profile Step Validation', () {
      testWidgets('should prevent navigation from academic profile step when fields are empty', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // First, complete basic information step
        await _fillBasicInformationStep(tester);
        
        // Move to academic profile step
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Verify we're on academic profile step
        expect(find.text('Academic Profile'), findsOneWidget);
        
        // Try to move to next step without selecting required fields
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Should still be on academic profile step
        expect(find.text('Academic Profile'), findsOneWidget);
        expect(find.textContaining('Academic Profile Error'), findsOneWidget);
      });
    });

    group('Subject Selection Step Validation', () {
      testWidgets('should prevent navigation from subject selection step when no subjects selected', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Complete basic information and academic profile steps
        await _fillBasicInformationStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillAcademicProfileStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Verify we're on subject selection step
        expect(find.text('Subject Selection'), findsOneWidget);
        
        // Try to move to next step without selecting subjects
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Should still be on subject selection step
        expect(find.text('Subject Selection'), findsOneWidget);
        expect(find.textContaining('Subject Selection Error'), findsOneWidget);
      });
    });

    group('Study Goals Step Validation', () {
      testWidgets('should prevent registration when study goals are incomplete', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Complete all previous steps
        await _fillBasicInformationStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillAcademicProfileStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillSubjectSelectionStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        // Verify we're on study goals step
        expect(find.text('Study Goals'), findsOneWidget);
        
        // Try to complete registration without setting goals
        final completeButton = find.text('Complete Registration');
        if (completeButton.evaluate().isNotEmpty) {
          await tester.tap(completeButton);
          await tester.pumpAndSettle();
          
          // Should show validation error
          expect(find.textContaining('Study Goals Error'), findsOneWidget);
        }
      });
    });

    group('Regression Tests', () {
      testWidgets('should not break existing successful registration flow', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        
        // Complete entire registration flow with valid data
        await _fillBasicInformationStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillAcademicProfileStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillSubjectSelectionStep(tester);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        await _fillStudyGoalsStep(tester);
        
        // Accept terms
        final termsCheckbox = find.byType(Checkbox);
        if (termsCheckbox.evaluate().isNotEmpty) {
          await tester.tap(termsCheckbox);
          await tester.pumpAndSettle();
        }
        
        // Complete registration - this should work without validation errors
        final completeButton = find.text('Complete Registration');
        if (completeButton.evaluate().isNotEmpty) {
          await tester.tap(completeButton);
          await tester.pumpAndSettle();
          
          // Should not show validation errors if all fields are properly filled
          expect(find.textContaining('Error'), findsNothing);
        }
      });
    });
  });
}

// Helper functions to fill form steps
Future<void> _fillBasicInformationStep(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
  await tester.enterText(find.byType(TextFormField).at(1), '+2348012345678');
  await tester.enterText(find.byType(TextFormField).at(2), 'john@example.com');
  await tester.enterText(find.byType(TextFormField).at(3), 'Password123!');
  await tester.enterText(find.byType(TextFormField).at(4), 'Password123!');
  await tester.pumpAndSettle();
}

Future<void> _fillAcademicProfileStep(WidgetTester tester) async {
  // Select class dropdown
  final classDropdown = find.byType(DropdownButtonFormField<String>).first;
  await tester.tap(classDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('SS3'));
  await tester.pumpAndSettle();
  
  // Select school type dropdown
  final schoolTypeDropdown = find.byType(DropdownButtonFormField<String>).last;
  await tester.tap(schoolTypeDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Public School'));
  await tester.pumpAndSettle();
  
  // Select study focus (at least one)
  final jamb = find.text('JAMB Preparation');
  if (jamb.evaluate().isNotEmpty) {
    await tester.tap(jamb);
    await tester.pumpAndSettle();
  }
}

Future<void> _fillSubjectSelectionStep(WidgetTester tester) async {
  // Select at least one science subject
  final physics = find.text('Physics');
  if (physics.evaluate().isNotEmpty) {
    await tester.tap(physics);
    await tester.pumpAndSettle();
  }
}

Future<void> _fillStudyGoalsStep(WidgetTester tester) async {
  // Set target exam date (find and tap date picker)
  final datePicker = find.textContaining('Select Date');
  if (datePicker.evaluate().isNotEmpty) {
    await tester.tap(datePicker.first);
    await tester.pumpAndSettle();
    
    // Select a future date
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
  
  // Select study hours per week
  final studyHours = find.text('10-15 hours');
  if (studyHours.evaluate().isNotEmpty) {
    await tester.tap(studyHours);
    await tester.pumpAndSettle();
  }
}