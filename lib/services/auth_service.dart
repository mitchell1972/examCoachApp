import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user_model.dart';

abstract class AuthService {
  Future<void> sendOTP(String phoneNumber);
  Future<UserModel?> verifyOTP(String phoneNumber, String code);
  UserModel? get currentUser;
  Stream<UserModel?> get authStateChanges;
  Future<void> signOut();
}

class DemoAuthService implements AuthService {
  final Logger _logger = Logger();
  UserModel? _currentUser;

  DemoAuthService() {
    _logger.i('🎭 Demo Authentication Service initialized');
    _logger.i('ℹ️  Use demo code: 123456 for verification');
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _logger.i('📱 Demo mode: Simulating OTP send to ${_maskPhoneNumber(phoneNumber)}');
      await Future.delayed(const Duration(seconds: 1));
      _logger.i('✅ Demo OTP sent successfully');
    } catch (e) {
      _logger.e('❌ Failed to send OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  @override
  Future<UserModel?> verifyOTP(String phoneNumber, String code) async {
    try {
      _logger.i('🔐 Demo mode: Verifying OTP for ${_maskPhoneNumber(phoneNumber)}');
      await Future.delayed(const Duration(seconds: 1));
      
      if (code == '123456') {
        final userId = 'demo-user-${DateTime.now().millisecondsSinceEpoch}';
        _currentUser = UserModel(
          id: userId,
          phoneNumber: phoneNumber,
          name: 'Demo User',
          email: 'demo@example.com',
          examInterest: '',
          examDate: null,
          studyHoursPerDay: 0,
          targetScore: '',
          createdAt: DateTime.now(),
        );
        _logger.i('✅ Demo OTP verified successfully');
        return _currentUser;
      } else {
        _logger.w('❌ Demo OTP verification failed: incorrect code');
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      _logger.e('❌ OTP verification error: $e');
      throw Exception('Verification failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _logger.i('Signing out user');
    _currentUser = null;
    _logger.i('✅ User signed out successfully');
  }
  
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 8) return phoneNumber;
    final start = phoneNumber.substring(0, phoneNumber.length - 8);
    final end = phoneNumber.substring(phoneNumber.length - 4);
    return '$start****$end';
  }
}
