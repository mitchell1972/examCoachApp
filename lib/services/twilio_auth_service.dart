import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user_model.dart';

// This service requires a backend endpoint to securely interact with Twilio
// Never put Twilio credentials directly in your Flutter app!

abstract class AuthService {
  Future<void> sendOTP(String phoneNumber);
  Future<UserModel?> verifyOTP(String phoneNumber, String code);
  UserModel? get currentUser;
  Stream<UserModel?> get authStateChanges;
  Future<void> signOut();
}

class TwilioAuthService implements AuthService {
  final Logger _logger = Logger();
  UserModel? _currentUser;
  
  // Your backend API endpoint
  // Replace with your actual backend URL
  static const String _baseUrl = 'https://exam-coach-app.vercel.app/api';
  
  // For development, you can use demo mode
  final bool _isDemoMode;
  
  TwilioAuthService({bool isDemoMode = false}) : _isDemoMode = isDemoMode;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _logger.i('Sending OTP to $phoneNumber');
      
      if (_isDemoMode) {
        _logger.i('🎭 Demo mode: Simulating OTP send');
        await Future.delayed(const Duration(seconds: 1));
        _logger.i('✅ Demo OTP sent successfully');
        return;
      }
      
      // In production, call your backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send OTP: ${response.body}');
      }
      
      _logger.i('✅ OTP sent successfully');
    } catch (e) {
      _logger.e('❌ Failed to send OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  @override
  Future<UserModel?> verifyOTP(String phoneNumber, String code) async {
    try {
      _logger.i('Verifying OTP for $phoneNumber');
      
      if (_isDemoMode) {
        _logger.i('🔐 Demo mode: Verifying OTP');
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
      }
      
      // In production, call your backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'code': code,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel(
          id: data['userId'],
          phoneNumber: phoneNumber,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          examInterest: '',
          examDate: null,
          studyHoursPerDay: 0,
          targetScore: '',
          createdAt: DateTime.now(),
        );
        _logger.i('✅ OTP verified successfully');
        return _currentUser;
      } else {
        _logger.e('❌ OTP verification failed: ${response.body}');
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
}

// Demo Authentication Service for development
class DemoAuthService extends TwilioAuthService {
  DemoAuthService() : super(isDemoMode: true) {
    _logger.i('🎭 Development: Using Demo Authentication...');
    _logger.i('ℹ️  NO REAL SMS WILL BE SENT - Use demo code: 123456');
  }
  
  @override
  Future<void> sendOTP(String phoneNumber) async {
    _logger.i('📱 Demo mode: Simulating OTP send to ${_maskPhoneNumber(phoneNumber)}');
    await super.sendOTP(phoneNumber);
  }
  
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 8) return phoneNumber;
    final start = phoneNumber.substring(0, phoneNumber.length - 8);
    final end = phoneNumber.substring(phoneNumber.length - 4);
    return '$start****$end';
  }
}
