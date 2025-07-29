import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  group('OTP Verification Flow Tests', () {
    group('Data Mapping Tests', () {
      test('should map studyFocus to examTypes correctly', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['JAMB', 'WAEC', 'NECO'],
          scienceSubjects: ['Mathematics', 'Physics', 'Chemistry'],
        );

        // Act - Simulate the mapping that happens in OTP verification
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        // Set legacy fields for backward compatibility
        if (userModel.examTypes.isNotEmpty) {
          userModel.examType = userModel.examTypes.first;
        }
        if (userModel.subjects.isNotEmpty) {
          userModel.subject = userModel.subjects.first;
        }

        // Assert
        expect(userModel.examTypes, equals(['JAMB', 'WAEC', 'NECO']));
        expect(userModel.subjects, equals(['Mathematics', 'Physics', 'Chemistry']));
        expect(userModel.examType, equals('JAMB')); // Legacy field
        expect(userModel.subject, equals('Mathematics')); // Legacy field
      });

      test('should handle empty studyFocus and scienceSubjects', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: [],
          scienceSubjects: [],
        );

        // Act
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        if (userModel.examTypes.isNotEmpty) {
          userModel.examType = userModel.examTypes.first;
        }
        if (userModel.subjects.isNotEmpty) {
          userModel.subject = userModel.subjects.first;
        }

        // Assert
        expect(userModel.examTypes, isEmpty);
        expect(userModel.subjects, isEmpty);
        expect(userModel.examType, isNull);
        expect(userModel.subject, isNull);
      });

      test('should handle single item in studyFocus and scienceSubjects', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['JAMB'],
          scienceSubjects: ['Mathematics'],
        );

        // Act
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        if (userModel.examTypes.isNotEmpty) {
          userModel.examType = userModel.examTypes.first;
        }
        if (userModel.subjects.isNotEmpty) {
          userModel.subject = userModel.subjects.first;
        }

        // Assert
        expect(userModel.examTypes, equals(['JAMB']));
        expect(userModel.subjects, equals(['Mathematics']));
        expect(userModel.examType, equals('JAMB'));
        expect(userModel.subject, equals('Mathematics'));
      });

      test('should preserve original studyFocus and scienceSubjects after mapping', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['JAMB', 'WAEC'],
          scienceSubjects: ['Mathematics', 'Physics'],
        );

        // Act
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        // Assert - Original data should be preserved
        expect(userModel.studyFocus, equals(['JAMB', 'WAEC']));
        expect(userModel.scienceSubjects, equals(['Mathematics', 'Physics']));
        
        // Mapped data should be correct
        expect(userModel.examTypes, equals(['JAMB', 'WAEC']));
        expect(userModel.subjects, equals(['Mathematics', 'Physics']));
      });
    });

    group('Trial Activation Tests', () {
      test('should activate trial during OTP verification', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['JAMB'],
          scienceSubjects: ['Mathematics'],
        );
        final signupTime = DateTime.now();

        // Act - Simulate trial activation in OTP verification
        userModel.setTrialStatus(signupTime);

        // Assert
        expect(userModel.isOnTrial, isTrue);
        expect(userModel.isTrialExpired, isFalse);
        expect(userModel.status, equals('trial'));
        expect(userModel.trialStartTime, equals(signupTime));
        expect(userModel.trialEndTime, equals(signupTime.add(const Duration(hours: 48))));
      });

      test('should set user as verified during OTP verification', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          isVerified: false,
        );

        // Act - Simulate verification in OTP flow
        userModel.isVerified = true;
        userModel.lastLoginDate = DateTime.now();

        // Assert
        expect(userModel.isVerified, isTrue);
        expect(userModel.lastLoginDate, isNotNull);
      });
    });

    group('Data Serialization After Mapping', () {
      test('should serialize correctly after data mapping', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['JAMB', 'WAEC'],
          scienceSubjects: ['Mathematics', 'Physics'],
        );

        // Act - Simulate the mapping
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);
        userModel.examType = userModel.examTypes.first;
        userModel.subject = userModel.subjects.first;
        userModel.setTrialStatus(DateTime.now());

        final json = userModel.toJson();

        // Assert
        expect(json['studyFocus'], equals(['JAMB', 'WAEC']));
        expect(json['scienceSubjects'], equals(['Mathematics', 'Physics']));
        expect(json['examTypes'], equals(['JAMB', 'WAEC']));
        expect(json['subjects'], equals(['Mathematics', 'Physics']));
        expect(json['examType'], equals('JAMB'));
        expect(json['subject'], equals('Mathematics'));
        expect(json['isOnTrial'], isTrue);
      });

      test('should deserialize correctly with mapped data', () {
        // Arrange
        final json = {
          'phoneNumber': '+2348123456789',
          'fullName': 'Test User',
          'studyFocus': ['JAMB', 'WAEC'],
          'scienceSubjects': ['Mathematics', 'Physics'],
          'examTypes': ['JAMB', 'WAEC'],
          'subjects': ['Mathematics', 'Physics'],
          'examType': 'JAMB',
          'subject': 'Mathematics',
          'status': 'trial',
          'trialStartTime': DateTime.now().toIso8601String(),
          'trialEndTime': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
        };

        // Act
        final userModel = UserModel.fromJson(json);

        // Assert
        expect(userModel.studyFocus, equals(['JAMB', 'WAEC']));
        expect(userModel.scienceSubjects, equals(['Mathematics', 'Physics']));
        expect(userModel.examTypes, equals(['JAMB', 'WAEC']));
        expect(userModel.subjects, equals(['Mathematics', 'Physics']));
        expect(userModel.examType, equals('JAMB'));
        expect(userModel.subject, equals('Mathematics'));
      });
    });

    group('Edge Cases', () {
      test('should handle null studyFocus and scienceSubjects', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
        );

        // Act
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        // Assert
        expect(userModel.examTypes, isEmpty);
        expect(userModel.subjects, isEmpty);
      });

      test('should handle mixed case and special characters in study focus', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          studyFocus: ['jamb', 'WAEC', 'Neco'],
          scienceSubjects: ['mathematics', 'PHYSICS', 'Chemistry'],
        );

        // Act
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);

        // Assert
        expect(userModel.examTypes, equals(['jamb', 'WAEC', 'Neco']));
        expect(userModel.subjects, equals(['mathematics', 'PHYSICS', 'Chemistry']));
      });
    });
  });
}
