import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  group('Multi-Selection Feature Unit Tests', () {
    late UserModel testUserModel;

    setUp(() {
      testUserModel = UserModel(
        fullName: 'Test User',
        phoneNumber: '+1234567890',
        email: 'test@example.com',
        currentClass: 'SS3',
        schoolType: 'Public School',
        studyFocus: [],
        scienceSubjects: [],
      );
    });

    group('UserModel Multi-Selection Tests', () {
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

      test('should handle empty lists correctly', () {
        expect(testUserModel.examTypes, isEmpty);
        expect(testUserModel.subjects, isEmpty);
      });

      test('should handle single selections in lists', () {
        testUserModel.examTypes = ['WAEC'];
        testUserModel.subjects = ['Mathematics'];
        
        expect(testUserModel.examTypes.length, equals(1));
        expect(testUserModel.subjects.length, equals(1));
        expect(testUserModel.examTypes.first, equals('WAEC'));
        expect(testUserModel.subjects.first, equals('Mathematics'));
      });
    });

    group('Integration Scenario Tests', () {
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

      test('should handle mixed selection scenarios', () {
        // Test single exam, multiple subjects
        testUserModel.examType = 'WAEC';
        testUserModel.examTypes = ['WAEC'];
        testUserModel.subjects = ['Mathematics', 'English Language', 'Physics'];
        testUserModel.subject = 'Mathematics';

        expect(testUserModel.examTypes.length, equals(1));
        expect(testUserModel.subjects.length, equals(3));
        
        final json = testUserModel.toJson();
        final newModel = UserModel.fromJson(json);
        
        expect(newModel.examTypes, equals(['WAEC']));
        expect(newModel.subjects, equals(['Mathematics', 'English Language', 'Physics']));
      });

      test('should handle null and empty values in JSON', () {
        final jsonWithNulls = {
          'phoneNumber': '+1234567890',
          'examType': 'WAEC',
          'subject': 'Mathematics',
          'examTypes': null,
          'subjects': null,
          'status': 'trial',
        };

        final model = UserModel.fromJson(jsonWithNulls);
        
        expect(model.examTypes, isEmpty);
        expect(model.subjects, isEmpty);
        expect(model.examType, equals('WAEC'));
        expect(model.subject, equals('Mathematics'));
      });
    });
  });
}
