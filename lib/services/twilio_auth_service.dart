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
      
      _logger.i('Received response from send-otp API: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        _logger.i('✅ OTP sent successfully');
      } else {
        final errorBody = response.body;
        _logger.e('❌ Backend API error (${response.statusCode}): $errorBody');
        
        // Try to parse error response
        String errorMessage = 'Failed to send OTP';
        try {
          final errorData = jsonDecode(errorBody);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // If we can't parse JSON, use the raw error body
          errorMessage = errorBody;
        }
        
        // If backend is not configured, provide helpful error message
        if (response.statusCode == 500 && errorMessage.contains('Failed to send verification code')) {
          throw Exception('Backend SMS service not configured. Please set up Twilio credentials on Vercel.');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to send OTP: $e', error: e, stackTrace: stackTrace);
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> verifyOTP(String phoneNumber, String code) async {
    try {
      _logger.i('Verifying OTP for $phoneNumber with code: $code');
      
      if (_isDemoMode) {
        _logger.i('🔐 Demo mode: Verifying OTP code: $code');
        await Future.delayed(const Duration(seconds: 1));
        
        // Accept multiple demo codes for better user experience
        final validDemoCodes = ['123456', '000000', '111111', '555555'];
        
        if (validDemoCodes.contains(code)) {
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
          _logger.i('✅ Demo OTP verified successfully with code: $code');
          return _currentUser;
        } else {
          _logger.w('❌ Demo OTP verification failed. Code entered: $code');
          _logger.w('💡 Valid demo codes: ${validDemoCodes.join(", ")}');
          throw Exception('Invalid verification code. Demo codes: ${validDemoCodes.join(", ")}');
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
      
      _logger.i('Received response from verify-otp API: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel(
          id: data['userId'] ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
          phoneNumber: phoneNumber,
          name: data['name'] ?? 'Verified User',
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
        final errorData = jsonDecode(response.body);
        _logger.e('❌ OTP verification failed: ${response.body}');
        throw Exception(errorData['error'] ?? 'Invalid verification code');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ OTP verification error: $e', error: e, stackTrace: stackTrace);
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Verification failed: ${e.toString()}');
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
    _logger.i('ℹ️  NO REAL SMS WILL BE SENT');
    _logger.i('📋 Valid demo codes: 123456, 000000, 111111, 555555');
  }
  
  @override
  Future<void> sendOTP(String phoneNumber) async {
    _logger.i('📱 Demo mode: Simulating OTP send to ${_maskPhoneNumber(phoneNumber)}');
    _logger.i('💡 Use any of these demo codes: 123456, 000000, 111111, 555555');
    await super.sendOTP(phoneNumber);
  }
  
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 8) return phoneNumber;
    final start = phoneNumber.substring(0, phoneNumber.length - 8);
    final end = phoneNumber.substring(phoneNumber.length - 4);
    return '$start****$end';
  }
}
