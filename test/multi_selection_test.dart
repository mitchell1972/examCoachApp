import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/user_model.dart';
import '../lib/screens/exam_selection_screen.dart';
import '../lib/screens/subject_selection_screen.dart';

void main() {
  group('Multi-Selection Feature Tests', () {
    late UserModel testUserModel;

    setUp(() {
      testUserModel = UserModel(
        phoneNumber: '+1234567890',
        status: 'trial',
      );
    });

    group('UserModel Tests', () {
      test('should support multiple exam types', () {
        testUserModel.examTypes = ['WAEC', 'JAMB'];
        
        expect(testUserModel.examTypes, contains('WAEC'));
        expect(testUserModel.examTypes, contains('JAMB'));
        expect(testUserModel.examTypes.length, equals(2));
      });

      test('should support multiple subjects', () {
        testUserModel.subjects = ['Mathematics', 'English Language'];
        
        expect(testUserModel.subjects, contains('Mathematics'));
        expect(testUserModel.subjects, contains('English Language'));
        expect(testUserModel.subjects.length, equals(2));
      });

      test('should maintain backward compatibility with single exam type', () {
        testUserModel.examType = 'WAEC';
        testUserModel.examTypes = ['WAEC'];
        
        expect(testUserModel.examType, equals('WAEC'));
        expect(testUserModel.examTypes.first, equals('WAEC'));
      });

      test('should maintain backward compatibility with single subject', () {
        testUserModel.subject = 'Mathematics';
        testUserModel.subjects = ['Mathematics'];
        
        expect(testUserModel.subject, equals('Mathematics'));
        expect(testUserModel.subjects.first, equals('Mathematics'));
      });

      test('should serialize and deserialize correctly with new fields', () {
        testUserModel.examTypes = ['WAEC', 'JAMB'];
        testUserModel.subjects = ['Mathematics', 'English Language'];
        
        final json = testUserModel.toJson();
        final deserializedModel = UserModel.fromJson(json);
        
        expect(deserializedModel.examTypes, equals(['WAEC', 'JAMB']));
        expect(deserializedModel.subjects, equals(['Mathematics', 'English Language']));
      });

      test('should handle "Both" exam selection correctly', () {
        testUserModel.examType = 'Both';
        testUserModel.examTypes = ['WAEC', 'JAMB'];
        
        expect(testUserModel.examType, equals('Both'));
        expect(testUserModel.examTypes, containsAll(['WAEC', 'JAMB']));
      });
    });

    group('ExamSelectionScreen Tests', () {
      testWidgets('should display "Both" option in exam selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ExamSelectionScreen(userModel: testUserModel),
          ),
        );

        expect(find.text('Both'), findsOneWidget);
        expect(find.text('WAEC & JAMB Combined'), findsOneWidget);
      });

      testWidgets('should navigate to subject selection when exam is selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ExamSelectionScreen(userModel: testUserModel),
          ),
        );

        // Tap on "Both" option
        await tester.tap(find.text('Both'));
        await tester.pumpAndSettle();

        // Should navigate to subject selection screen
        expect(find.byType(SubjectSelectionScreen), findsOneWidget);
      });
    });

    group('SubjectSelectionScreen Tests', () {
      setUp(() {
        testUserModel.examType = 'Both';
        testUserModel.examTypes = ['WAEC', 'JAMB'];
      });

      testWidgets('should display multiple subject options', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubjectSelectionScreen(userModel: testUserModel),
          ),
        );

        // Check for the actual short names used in the UI
        expect(find.text('Math'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Physics'), findsOneWidget);
        expect(find.text('Chemistry'), findsOneWidget);
        expect(find.text('Biology'), findsOneWidget);
        expect(find.text('Economics'), findsOneWidget);
      });

      testWidgets('should allow multiple subject selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubjectSelectionScreen(userModel: testUserModel),
          ),
        );

        // Select Math
        await tester.tap(find.text('Math'));
        await tester.pump();

        // Select English
        await tester.tap(find.text('English'));
        await tester.pump();

        // Both should be selected (check for check icons)
        expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      });

      testWidgets('should show finish button when subjects are selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubjectSelectionScreen(userModel: testUserModel),
          ),
        );

        // Initially no finish button
        expect(find.text('Finish Setup (1 selected)'), findsNothing);

        // Select a subject
        await tester.tap(find.text('Math'));
        await tester.pump();

        // Finish button should appear
        expect(find.text('Finish Setup (1 selected)'), findsOneWidget);

        // Select another subject
        await tester.tap(find.text('English'));
        await tester.pump();

        // Button text should update
        expect(find.text('Finish Setup (2 selected)'), findsOneWidget);
      });

      testWidgets('should allow deselecting subjects', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubjectSelectionScreen(userModel: testUserModel),
          ),
        );

        // Select Math
        await tester.tap(find.text('Math'));
        await tester.pump();

        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // Deselect Math
        await tester.tap(find.text('Math'));
        await tester.pump();

        expect(find.byIcon(Icons.check_circle), findsNothing);
      });

      testWidgets('should update user model with selected data on finish', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubjectSelectionScreen(userModel: testUserModel),
          ),
        );

        // Select subjects
        await tester.tap(find.text('Math'));
        await tester.pump();
        await tester.tap(find.text('English'));
        await tester.pump();

        // Tap finish button
        await tester.tap(find.text('Finish Setup (2 selected)'));
        await tester.pump();

        // Wait for processing
        await tester.pump(const Duration(seconds: 3));

        // Check that user model was updated
        expect(testUserModel.subjects, contains('Mathematics'));
        expect(testUserModel.subjects, contains('English Language'));
        expect(testUserModel.examTypes, containsAll(['WAEC', 'JAMB']));
      });
    });

    group('Integration Tests', () {
      test('should handle complete flow: Both exams + multiple subjects', () {
        // Simulate selecting "Both" exams
        testUserModel.examType = 'Both';
        testUserModel.examTypes = ['WAEC', 'JAMB'];

        // Simulate selecting multiple subjects
        testUserModel.subjects = ['Mathematics', 'English Language'];
        testUserModel.subject = 'Mathematics'; // For backward compatibility

        // Verify the final state matches the scenario
        expect(testUserModel.examType, equals('Both'));
        expect(testUserModel.examTypes, equals(['WAEC', 'JAMB']));
        expect(testUserModel.subjects, equals(['Mathematics', 'English Language']));
        
        // Verify backward compatibility
        expect(testUserModel.subject, equals('Mathematics'));
      });

      test('should serialize complete multi-selection data correctly', () {
        testUserModel.examType = 'Both';
        testUserModel.examTypes = ['WAEC', 'JAMB'];
        testUserModel.subjects = ['Mathematics', 'English Language'];
        testUserModel.subject = 'Mathematics';

        final json = testUserModel.toJson();
        
        expect(json['examType'], equals('Both'));
        expect(json['examTypes'], equals(['WAEC', 'JAMB']));
        expect(json['subjects'], equals(['Mathematics', 'English Language']));
        expect(json['subject'], equals('Mathematics'));

        // Test deserialization
        final newModel = UserModel.fromJson(json);
        expect(newModel.examType, equals('Both'));
        expect(newModel.examTypes, equals(['WAEC', 'JAMB']));
        expect(newModel.subjects, equals(['Mathematics', 'English Language']));
        expect(newModel.subject, equals('Mathematics'));
      });
    });
  });
}
