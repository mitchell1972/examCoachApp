import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/phone_input_screen.dart';

void main() {
  group('Phone Validation Tests', () {
    group('Phone Input Validation', () {
      testWidgets('should show error when phone field is empty and Send OTP is tapped', (WidgetTester tester) async {
        // Build the PhoneInputScreen widget
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Verify the screen loads
        expect(find.byType(PhoneInputScreen), findsOneWidget);
        expect(find.text('Verify Your Phone'), findsOneWidget);

        // Find the phone input field and Send OTP button
        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        expect(phoneField, findsOneWidget);
        expect(sendOtpButton, findsOneWidget);

        // Leave phone field empty (it should be empty by default)
        // Tap the Send OTP button
        await tester.tap(sendOtpButton);
        await tester.pump(); // Trigger a frame

        // Verify error message appears
        expect(find.text('Please enter your phone number'), findsOneWidget);
      });

      testWidgets('should show error for phone number without country code', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Enter phone number without country code
        await tester.enterText(phoneField, '7940361848');
        await tester.tap(sendOtpButton);
        await tester.pump();

        // Should show error for missing country code
        expect(find.text('Please include country code (e.g., +44)'), findsOneWidget);
      });

      testWidgets('should show error for invalid phone number format', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Test too short number
        await tester.enterText(phoneField, '+123');
        await tester.tap(sendOtpButton);
        await tester.pump();

        // Should show validation error
        expect(find.text('Please enter a valid phone number (10-14 digits)'), findsOneWidget);
      });
    });

    group('Phone Input Screen UI Tests', () {
      testWidgets('should display all required UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Check for main UI elements
        expect(find.text('Verify Your Phone'), findsOneWidget);
        expect(find.text('Enter your phone number to get started'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Send OTP'), findsOneWidget);
        expect(find.byIcon(Icons.phone_android), findsOneWidget);
      });

      testWidgets('should show environment notice', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Should show demo mode notice
        expect(find.textContaining('DEMO MODE'), findsOneWidget);
        expect(find.textContaining('No real SMS - Use code: 123456'), findsOneWidget);
      });

      testWidgets('should show proper hint text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Check for hint text
        expect(find.text('+1 234 567 8900'), findsOneWidget);
      });

      testWidgets('should have proper app bar', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Should have app bar with title
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Enter Phone Number'), findsOneWidget);
      });
    });

    group('Form Validation Logic', () {
      testWidgets('should validate empty input correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Test empty field
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please enter your phone number'), findsOneWidget);
      });

      testWidgets('should validate country code requirement', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Test number without country code
        await tester.enterText(phoneField, '1234567890');
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please include country code (e.g., +44)'), findsOneWidget);
      });

      testWidgets('should validate phone number length', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Test too short number
        await tester.enterText(phoneField, '+123');
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please enter a valid phone number (10-14 digits)'), findsOneWidget);
      });
    });

    group('Scenario: Prevent incomplete signup', () {
      testWidgets('Given I am on the signup screen, When I leave the phone field blank And I tap "Send OTP", Then I see error "Please enter your phone number"', (WidgetTester tester) async {
        // Given I am on the signup screen
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Verify we're on the phone input screen
        expect(find.byType(PhoneInputScreen), findsOneWidget);
        expect(find.text('Verify Your Phone'), findsOneWidget);

        // When I leave the phone field blank
        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');
        
        expect(phoneField, findsOneWidget);
        expect(sendOtpButton, findsOneWidget);
        
        // Phone field should be empty by default
        final textField = tester.widget<TextFormField>(phoneField);
        expect(textField.controller?.text ?? '', isEmpty);

        // And I tap "Send OTP"
        await tester.tap(sendOtpButton);
        await tester.pump(); // Trigger validation

        // Then I see error "Please enter your phone number"
        expect(find.text('Please enter your phone number'), findsOneWidget);
      });

      testWidgets('should prevent navigation when phone validation fails', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final sendOtpButton = find.text('Send OTP');

        // Try to proceed without entering phone number
        await tester.tap(sendOtpButton);
        await tester.pump();

        // Should show error and stay on same screen
        expect(find.text('Please enter your phone number'), findsOneWidget);
        expect(find.byType(PhoneInputScreen), findsOneWidget);
      });

      testWidgets('should show error for various invalid inputs', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        final phoneField = find.byType(TextFormField);
        final sendOtpButton = find.text('Send OTP');

        // Test empty string
        await tester.enterText(phoneField, '');
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please enter your phone number'), findsOneWidget);

        // Test number without country code
        await tester.enterText(phoneField, '1234567890');
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please include country code (e.g., +44)'), findsOneWidget);

        // Test too short number
        await tester.enterText(phoneField, '+123');
        await tester.tap(sendOtpButton);
        await tester.pump();
        expect(find.text('Please enter a valid phone number (10-14 digits)'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhoneInputScreen(),
          ),
        );

        // Check for semantic elements
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
      });
    });
  });
}
