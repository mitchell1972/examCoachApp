import 'package:flutter_test/flutter_test.dart';
import 'package:exam_coach_app/models/user_model.dart';

void main() {
  group('Dashboard Display Tests', () {
    group('Exam Display Text Tests', () {
      test('should display single exam type correctly', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );

        // Act - Simulate dashboard display logic
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final displayText = getExamDisplayText();

        // Assert
        expect(displayText, equals('JAMB'));
      });

      test('should display multiple exam types with ampersand separator', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB', 'WAEC', 'NECO'],
          subjects: ['Mathematics'],
        );

        // Act
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final displayText = getExamDisplayText();

        // Assert
        expect(displayText, equals('JAMB & WAEC & NECO'));
      });

      test('should fallback to legacy examType when examTypes is empty', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examType: 'JAMB', // Legacy field
          examTypes: [], // Empty new field
          subjects: ['Mathematics'],
        );

        // Act
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final displayText = getExamDisplayText();

        // Assert
        expect(displayText, equals('JAMB'));
      });

      test('should display N/A when both examTypes and examType are empty/null', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: [],
          subjects: ['Mathematics'],
        );

        // Act
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final displayText = getExamDisplayText();

        // Assert
        expect(displayText, equals('N/A'));
      });
    });

    group('Subject Display Text Tests', () {
      test('should display single subject correctly', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );

        // Act
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        final displayText = getSubjectDisplayText();

        // Assert
        expect(displayText, equals('Mathematics'));
      });

      test('should display multiple subjects with ampersand separator', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics', 'Physics', 'Chemistry', 'Biology'],
        );

        // Act
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        final displayText = getSubjectDisplayText();

        // Assert
        expect(displayText, equals('Mathematics & Physics & Chemistry & Biology'));
      });

      test('should fallback to legacy subject when subjects is empty', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subject: 'Mathematics', // Legacy field
          subjects: [], // Empty new field
        );

        // Act
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        final displayText = getSubjectDisplayText();

        // Assert
        expect(displayText, equals('Mathematics'));
      });

      test('should display N/A when both subjects and subject are empty/null', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: [],
        );

        // Act
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        final displayText = getSubjectDisplayText();

        // Assert
        expect(displayText, equals('N/A'));
      });
    });

    group('Trial Badge Display Tests', () {
      test('should display trial badge when user is on trial', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );
        userModel.setTrialStatus(DateTime.now());

        // Act
        final trialMessage = userModel.trialDisplayMessage;
        final isOnTrial = userModel.isOnTrial;
        final isExpired = userModel.isTrialExpired;

        // Assert
        expect(trialMessage, isNotNull);
        expect(isOnTrial, isTrue);
        expect(isExpired, isFalse);
        expect(trialMessage, contains('Free trial ends at'));
      });

      test('should display expired badge when trial is expired', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );
        // Set trial to expired (48 hours ago)
        final expiredTime = DateTime.now().subtract(const Duration(hours: 49));
        userModel.setTrialStatus(expiredTime);

        // Act
        final trialMessage = userModel.trialDisplayMessage;
        final isOnTrial = userModel.isOnTrial;
        final isExpired = userModel.isTrialExpired;

        // Assert
        expect(trialMessage, equals('Trial expired'));
        expect(isOnTrial, isFalse);
        expect(isExpired, isTrue);
      });

      test('should not display trial badge when no trial data exists', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );

        // Act
        final trialMessage = userModel.trialDisplayMessage;

        // Assert
        expect(trialMessage, isNull);
      });
    });

    group('Account Information Display Tests', () {
      test('should display complete account information', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB', 'WAEC'],
          subjects: ['Mathematics', 'Physics'],
          status: 'trial',
        );

        // Act - Simulate account info display
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        final phoneDisplay = userModel.phoneNumber ?? 'N/A';
        final examDisplay = getExamDisplayText();
        final subjectDisplay = getSubjectDisplayText();
        final statusDisplay = userModel.status;

        // Assert
        expect(phoneDisplay, equals('+2348123456789'));
        expect(examDisplay, equals('JAMB & WAEC'));
        expect(subjectDisplay, equals('Mathematics & Physics'));
        expect(statusDisplay, equals('trial'));
      });

      test('should handle missing phone number gracefully', () {
        // Arrange
        final userModel = UserModel(
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics'],
        );

        // Act
        final phoneDisplay = userModel.phoneNumber ?? 'N/A';

        // Assert
        expect(phoneDisplay, equals('N/A'));
      });
    });

    group('Quiz Button Display Tests', () {
      test('should generate correct quiz button text', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: ['JAMB'],
          subjects: ['Mathematics', 'Physics'],
        );

        // Act - Simulate quiz button text generation
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final quizText = 'Starting ${getSubjectDisplayText()} quiz for ${getExamDisplayText()}...';

        // Assert
        expect(quizText, equals('Starting Mathematics & Physics quiz for JAMB...'));
      });

      test('should handle N/A values in quiz button text', () {
        // Arrange
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'Test User',
          examTypes: [],
          subjects: [],
        );

        // Act
        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        final quizText = 'Starting ${getSubjectDisplayText()} quiz for ${getExamDisplayText()}...';

        // Assert
        expect(quizText, equals('Starting N/A quiz for N/A...'));
      });
    });

    group('Integration Tests', () {
      test('should handle complete user flow from registration to dashboard display', () {
        // Arrange - Simulate user coming from registration
        final userModel = UserModel(
          phoneNumber: '+2348123456789',
          fullName: 'John Doe',
          currentClass: 'SS3',
          schoolType: 'Public School',
          studyFocus: ['JAMB', 'WAEC'],
          scienceSubjects: ['Mathematics', 'Physics', 'Chemistry'],
        );

        // Act - Simulate OTP verification mapping
        userModel.examTypes = List<String>.from(userModel.studyFocus);
        userModel.subjects = List<String>.from(userModel.scienceSubjects);
        userModel.examType = userModel.examTypes.first;
        userModel.subject = userModel.subjects.first;
        userModel.setTrialStatus(DateTime.now());

        // Simulate dashboard display functions
        String getExamDisplayText() {
          if (userModel.examTypes.isNotEmpty) {
            return userModel.examTypes.join(' & ');
          }
          return userModel.examType ?? 'N/A';
        }

        String getSubjectDisplayText() {
          if (userModel.subjects.isNotEmpty) {
            return userModel.subjects.join(' & ');
          }
          return userModel.subject ?? 'N/A';
        }

        // Assert - All dashboard elements should display correctly
        expect(userModel.phoneNumber, equals('+2348123456789'));
        expect(getExamDisplayText(), equals('JAMB & WAEC'));
        expect(getSubjectDisplayText(), equals('Mathematics & Physics & Chemistry'));
        expect(userModel.status, equals('trial'));
        expect(userModel.isOnTrial, isTrue);
        expect(userModel.trialDisplayMessage, isNotNull);
        expect(userModel.trialDisplayMessage, contains('Free trial ends at'));
      });
    });
  });
}
