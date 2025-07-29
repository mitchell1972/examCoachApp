import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phone Validation Tests', () {
    group('Nigerian Phone Number Validation', () {
      test('should accept valid Nigerian phone numbers with +234 prefix', () {
        // Arrange
        final validPhones = [
          '+2348123456789',
          '+2347012345678',
          '+2349087654321',
          '+2348012345678',
        ];

        // Act & Assert
        for (final phone in validPhones) {
          expect(isValidNigerianPhone(phone), isTrue, reason: 'Phone $phone should be valid');
        }
      });

      test('should accept valid Nigerian phone numbers with 234 prefix (no +)', () {
        // Arrange
        final validPhones = [
          '2348123456789',
          '2347012345678',
          '2349087654321',
          '2348012345678',
        ];

        // Act & Assert
        for (final phone in validPhones) {
          expect(isValidNigerianPhone(phone), isTrue, reason: 'Phone $phone should be valid');
        }
      });

      test('should accept valid Nigerian phone numbers with 0 prefix', () {
        // Arrange
        final validPhones = [
          '08123456789',
          '07012345678',
          '09087654321',
          '08012345678',
        ];

        // Act & Assert
        for (final phone in validPhones) {
          expect(isValidNigerianPhone(phone), isTrue, reason: 'Phone $phone should be valid');
        }
      });

      test('should reject invalid Nigerian phone numbers', () {
        // Arrange
        final invalidPhones = [
          '123456789',        // Too short
          '+23481234567890',  // Too long
          '+2341234567890',   // Wrong network code
          '+2348',            // Too short
          'abcdefghijk',      // Non-numeric
          '+234812345678a',   // Contains letters
          '',                 // Empty
          '+1234567890',      // Wrong country code
          '08123456',         // Too short
          '081234567890',     // Too long
        ];

        // Act & Assert
        for (final phone in invalidPhones) {
          expect(isValidNigerianPhone(phone), isFalse, reason: 'Phone $phone should be invalid');
        }
      });

      test('should handle phone numbers with spaces and special characters', () {
        // Arrange
        final phonesWithSpaces = [
          '+234 812 345 6789',
          '+234-812-345-6789',
          '+234 (812) 345-6789',
          '0812 345 6789',
          '0812-345-6789',
        ];

        // Act & Assert
        for (final phone in phonesWithSpaces) {
          final cleanedPhone = cleanPhoneNumber(phone);
          expect(isValidNigerianPhone(cleanedPhone), isTrue, 
                 reason: 'Cleaned phone $cleanedPhone (from $phone) should be valid');
        }
      });

      test('should normalize phone numbers correctly', () {
        // Arrange & Act & Assert
        expect(normalizeNigerianPhone('08123456789'), equals('+2348123456789'));
        expect(normalizeNigerianPhone('2348123456789'), equals('+2348123456789'));
        expect(normalizeNigerianPhone('+2348123456789'), equals('+2348123456789'));
        expect(normalizeNigerianPhone('0812 345 6789'), equals('+2348123456789'));
        expect(normalizeNigerianPhone('+234-812-345-6789'), equals('+2348123456789'));
      });

      test('should validate specific Nigerian network codes', () {
        // Arrange - Test major Nigerian network prefixes
        final networkCodes = {
          '0701': 'Airtel',
          '0702': 'Airtel', 
          '0703': 'MTN',
          '0704': 'MTN',
          '0705': 'Globacom',
          '0706': 'MTN',
          '0707': 'Airtel',
          '0708': 'Airtel',
          '0709': '9mobile',
          '0801': 'Airtel',
          '0802': 'Airtel',
          '0803': 'MTN',
          '0804': 'MTN',
          '0805': 'Globacom',
          '0806': 'MTN',
          '0807': 'Globacom',
          '0808': 'Airtel',
          '0809': '9mobile',
          '0810': 'MTN',
          '0811': 'Globacom',
          '0812': 'Airtel',
          '0813': 'MTN',
          '0814': 'MTN',
          '0815': 'Globacom',
          '0816': 'MTN',
          '0817': '9mobile',
          '0818': '9mobile',
          '0901': 'Airtel',
          '0902': 'Airtel',
          '0903': 'MTN',
          '0904': 'Airtel',
          '0905': 'Globacom',
          '0906': 'MTN',
          '0907': 'Airtel',
          '0908': '9mobile',
          '0909': '9mobile',
        };

        // Act & Assert
        for (final code in networkCodes.keys) {
          final phone = '${code}1234567';
          expect(isValidNigerianPhone(phone), isTrue, 
                 reason: 'Phone with network code $code should be valid');
        }
      });
    });

    group('International Phone Number Validation', () {
      test('should accept valid international phone numbers', () {
        // Arrange
        final validInternationalPhones = [
          '+1234567890',      // US
          '+447123456789',    // UK
          '+33123456789',     // France
          '+49123456789',     // Germany
          '+86123456789',     // China
        ];

        // Act & Assert
        for (final phone in validInternationalPhones) {
          expect(isValidInternationalPhone(phone), isTrue, 
                 reason: 'International phone $phone should be valid');
        }
      });

      test('should reject invalid international phone numbers', () {
        // Arrange
        final invalidInternationalPhones = [
          '1234567890',       // Missing +
          '+12345',           // Too short
          '+123456789012345', // Too long
          '+abc123456789',    // Contains letters
          '',                 // Empty
        ];

        // Act & Assert
        for (final phone in invalidInternationalPhones) {
          expect(isValidInternationalPhone(phone), isFalse, 
                 reason: 'International phone $phone should be invalid');
        }
      });
    });

    group('Phone Number Utilities', () {
      test('should clean phone numbers correctly', () {
        // Arrange & Act & Assert
        expect(cleanPhoneNumber('+234 812 345 6789'), equals('+2348123456789'));
        expect(cleanPhoneNumber('+234-812-345-6789'), equals('+2348123456789'));
        expect(cleanPhoneNumber('+234 (812) 345-6789'), equals('+2348123456789'));
        expect(cleanPhoneNumber('0812 345 6789'), equals('08123456789'));
        expect(cleanPhoneNumber(''), equals(''));
      });

      test('should format phone numbers for display', () {
        // Arrange & Act & Assert
        expect(formatPhoneForDisplay('+2348123456789'), equals('+234 812 345 6789'));
        expect(formatPhoneForDisplay('08123456789'), equals('0812 345 6789'));
        expect(formatPhoneForDisplay('+1234567890'), equals('+1 234 567 890'));
      });

      test('should extract country code correctly', () {
        // Arrange & Act & Assert
        expect(extractCountryCode('+2348123456789'), equals('234'));
        expect(extractCountryCode('+1234567890'), equals('1'));
        expect(extractCountryCode('+447123456789'), equals('44'));
        expect(extractCountryCode('08123456789'), isNull);
      });

      test('should detect phone number type', () {
        // Arrange & Act & Assert
        expect(getPhoneNumberType('+2348123456789'), equals('Nigerian Mobile'));
        expect(getPhoneNumberType('+1234567890'), equals('International'));
        expect(getPhoneNumberType('08123456789'), equals('Nigerian Local'));
        expect(getPhoneNumberType('invalid'), equals('Invalid'));
      });
    });
  });
}

// Helper functions for phone validation
bool isValidNigerianPhone(String phone) {
  final cleaned = cleanPhoneNumber(phone);
  
  // Check for +234 format
  if (cleaned.startsWith('+234')) {
    return cleaned.length == 14 && _isValidNigerianNetworkCode(cleaned.substring(4, 7));
  }
  
  // Check for 234 format (without +)
  if (cleaned.startsWith('234')) {
    return cleaned.length == 13 && _isValidNigerianNetworkCode(cleaned.substring(3, 6));
  }
  
  // Check for 0 format
  if (cleaned.startsWith('0')) {
    return cleaned.length == 11 && _isValidNigerianNetworkCode(cleaned.substring(1, 4));
  }
  
  return false;
}

bool _isValidNigerianNetworkCode(String code) {
  final validCodes = [
    '701', '702', '703', '704', '705', '706', '707', '708', '709',
    '801', '802', '803', '804', '805', '806', '807', '808', '809',
    '810', '811', '812', '813', '814', '815', '816', '817', '818',
    '901', '902', '903', '904', '905', '906', '907', '908', '909',
  ];
  return validCodes.contains(code);
}

bool isValidInternationalPhone(String phone) {
  // Check for letters before cleaning
  if (RegExp(r'[a-zA-Z]').hasMatch(phone)) return false;
  
  final cleaned = cleanPhoneNumber(phone);
  
  // Must start with + and be between 7 and 15 digits
  if (!cleaned.startsWith('+')) return false;
  
  final digits = cleaned.substring(1);
  if (digits.length < 6 || digits.length > 14) return false;
  
  // Must contain only digits after the +
  return RegExp(r'^\d+$').hasMatch(digits);
}

String cleanPhoneNumber(String phone) {
  // Remove all non-digit characters except +
  return phone.replaceAll(RegExp(r'[^\d+]'), '');
}

String normalizeNigerianPhone(String phone) {
  final cleaned = cleanPhoneNumber(phone);
  
  if (cleaned.startsWith('+234')) {
    return cleaned;
  } else if (cleaned.startsWith('234')) {
    return '+$cleaned';
  } else if (cleaned.startsWith('0') && cleaned.length == 11) {
    return '+234${cleaned.substring(1)}';
  }
  
  return cleaned;
}

String formatPhoneForDisplay(String phone) {
  final cleaned = cleanPhoneNumber(phone);
  
  if (cleaned.startsWith('+234') && cleaned.length == 14) {
    return '+234 ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
  } else if (cleaned.startsWith('0') && cleaned.length == 11) {
    return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
  } else if (cleaned.startsWith('+') && cleaned.length >= 10) {
    final countryCode = extractCountryCode(cleaned);
    final number = cleaned.substring(countryCode!.length + 1);
    if (number.length >= 6) {
      return '+$countryCode ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
  }
  
  return cleaned;
}

String? extractCountryCode(String phone) {
  final cleaned = cleanPhoneNumber(phone);
  
  if (!cleaned.startsWith('+')) return null;
  
  // Common country codes
  if (cleaned.startsWith('+234')) return '234';
  if (cleaned.startsWith('+1')) return '1';
  if (cleaned.startsWith('+44')) return '44';
  if (cleaned.startsWith('+33')) return '33';
  if (cleaned.startsWith('+49')) return '49';
  if (cleaned.startsWith('+86')) return '86';
  
  // Extract first 1-3 digits after +
  final match = RegExp(r'^\+(\d{1,3})').firstMatch(cleaned);
  return match?.group(1);
}

String getPhoneNumberType(String phone) {
  final cleaned = cleanPhoneNumber(phone);
  
  if (isValidNigerianPhone(cleaned)) {
    if (cleaned.startsWith('0')) {
      return 'Nigerian Local';
    } else {
      return 'Nigerian Mobile';
    }
  } else if (isValidInternationalPhone(cleaned)) {
    return 'International';
  } else {
    return 'Invalid';
  }
}
