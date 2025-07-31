import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password Validation Logic Tests', () {
    group('Password Strength Validation', () {
      test('should require minimum 8 characters', () {
        // Test short passwords
        expect(_validatePassword(''), equals('Password is required'));
        expect(_validatePassword('1234567'), equals('Password must be at least 8 characters long'));
        expect(_validatePassword('12345678'), isNot(equals('Password must be at least 8 characters long')));
      });

      test('should require uppercase letter', () {
        expect(_validatePassword('password123!'), equals('Password must contain at least one uppercase letter'));
        expect(_validatePassword('Password123!'), isNot(equals('Password must contain at least one uppercase letter')));
      });

      test('should require lowercase letter', () {
        expect(_validatePassword('PASSWORD123!'), equals('Password must contain at least one lowercase letter'));
        expect(_validatePassword('Password123!'), isNot(equals('Password must contain at least one lowercase letter')));
      });

      test('should require at least one number', () {
        expect(_validatePassword('Password!'), equals('Password must contain at least one number'));
        expect(_validatePassword('Password123!'), isNot(equals('Password must contain at least one number')));
      });

      test('should accept valid strong passwords', () {
        expect(_validatePassword('Password123!'), isNull);
        expect(_validatePassword('MySecure123'), isNull);
        expect(_validatePassword('Test1234'), isNull);
        expect(_validatePassword('AbC123xyz'), isNull);
      });
    });

    group('Password Confirmation Validation', () {
      test('should require confirmation password', () {
        expect(_validateConfirmPassword('', 'Password123!'), equals('Please confirm your password'));
        expect(_validateConfirmPassword(null, 'Password123!'), equals('Please confirm your password'));
      });

      test('should reject mismatched passwords', () {
        expect(_validateConfirmPassword('Different123!', 'Password123!'), equals('Passwords do not match'));
        expect(_validateConfirmPassword('password123!', 'Password123!'), equals('Passwords do not match'));
        expect(_validateConfirmPassword('Password123', 'Password123!'), equals('Passwords do not match'));
      });

      test('should accept matching passwords', () {
        expect(_validateConfirmPassword('Password123!', 'Password123!'), isNull);
        expect(_validateConfirmPassword('MySecure123', 'MySecure123'), isNull);
        expect(_validateConfirmPassword('test', 'test'), isNull); // Even if original is weak, confirmation should match
      });

      test('should be case sensitive', () {
        expect(_validateConfirmPassword('password123!', 'Password123!'), equals('Passwords do not match'));
        expect(_validateConfirmPassword('PASSWORD123!', 'Password123!'), equals('Passwords do not match'));
      });

      test('should handle special characters correctly', () {
        expect(_validateConfirmPassword('Pass@123!', 'Pass@123!'), isNull);
        expect(_validateConfirmPassword('Pass@123!', 'Pass@123'), equals('Passwords do not match'));
        expect(_validateConfirmPassword('Test#\$%123', 'Test#\$%123'), isNull);
      });

      test('should handle spaces correctly', () {
        expect(_validateConfirmPassword('Pass word123!', 'Pass word123!'), isNull);
        expect(_validateConfirmPassword('Password123!', 'Password123! '), equals('Passwords do not match'));
        expect(_validateConfirmPassword(' Password123!', 'Password123!'), equals('Passwords do not match'));
      });
    });

    group('Edge Cases', () {
      test('should handle unicode characters', () {
        expect(_validateConfirmPassword('Pássword123!', 'Pássword123!'), isNull);
        expect(_validateConfirmPassword('Pássword123!', 'Password123!'), equals('Passwords do not match'));
      });

      test('should handle very long passwords', () {
        final longPassword = 'A' * 100 + '123!';
        expect(_validateConfirmPassword(longPassword, longPassword), isNull);
        expect(_validateConfirmPassword(longPassword, longPassword.substring(0, 50)), equals('Passwords do not match'));
      });

      test('should handle empty vs null correctly', () {
        expect(_validateConfirmPassword('', 'Password123!'), equals('Please confirm your password'));
        expect(_validateConfirmPassword(null, 'Password123!'), equals('Please confirm your password'));
        expect(_validateConfirmPassword('Password123!', ''), equals('Passwords do not match'));
      });
    });
  });
}

// Helper functions that mirror the logic from registration_screen.dart
String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  
  // Check for at least one uppercase letter
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Password must contain at least one uppercase letter';
  }
  
  // Check for at least one lowercase letter
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Password must contain at least one lowercase letter';
  }
  
  // Check for at least one digit
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Password must contain at least one number';
  }
  
  return null;
}

String? _validateConfirmPassword(String? confirmValue, String originalValue) {
  if (confirmValue == null || confirmValue.isEmpty) {
    return 'Please confirm your password';
  }
  
  if (confirmValue != originalValue) {
    return 'Passwords do not match';
  }
  
  return null;
}