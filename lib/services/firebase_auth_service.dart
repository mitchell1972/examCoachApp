import 'dart:async';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Pure Demo Firebase Authentication Service
/// Simulates phone verification for demo purposes without Firebase
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // Demo state tracking
  String? _verificationId;
  DateTime? _lastOtpSent;
  int _otpAttempts = 0;
  static const int _maxOtpAttempts = 3;
  static const Duration _otpCooldown = Duration(minutes: 1);
  static const String _demoOtp = '123456';

  /// Initialize the demo service (always succeeds)
  Future<void> initialize() async {
    try {
      _logger.i('🎭 Demo Firebase Auth Service: Initializing...');
      
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 500));
       
      _logger.i('✅ Demo Firebase Auth Service: Initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('❌ Demo service initialization failed', error: error, stackTrace: stackTrace);
      // In demo mode, we always continue even if there are errors
    }
  }

  /// Send OTP to phone number (demo simulation)
  Future<PhoneVerificationResult> sendOTP(String phoneNumber) async {
    try {
      _logger.i('📱 Demo mode: Simulating OTP send to ${_maskPhoneNumber(phoneNumber)}');

      // Check rate limiting
      if (_lastOtpSent != null && 
          DateTime.now().difference(_lastOtpSent!) < _otpCooldown) {
        final remaining = _otpCooldown - DateTime.now().difference(_lastOtpSent!);
        return PhoneVerificationResult.error(
          error: PhoneAuthError.tooManyRequests,
          message: 'Please wait ${remaining.inSeconds} seconds before requesting another code.',
        );
      }

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return PhoneVerificationResult.error(
          error: PhoneAuthError.networkError,
          message: 'No internet connection. Please check your network and try again.',
        );
      }

      // Validate phone number format (basic validation)
      if (!_isValidPhoneNumber(phoneNumber)) {
        return PhoneVerificationResult.error(
          error: PhoneAuthError.invalidPhoneNumber,
          message: 'Invalid phone number format. Please enter a valid number with country code.',
        );
      }

      // Simulate OTP sending
      await Future.delayed(const Duration(seconds: 2));

      // Generate demo verification ID
      _verificationId = 'demo-verification-${DateTime.now().millisecondsSinceEpoch}';
      _lastOtpSent = DateTime.now();
      _otpAttempts = 0;

      _logger.i('✅ Demo OTP sent successfully to ${_maskPhoneNumber(phoneNumber)}');

      return PhoneVerificationResult.success(
        verificationId: _verificationId!,
        message: '📱 Demo OTP "$_demoOtp" sent to $phoneNumber',
      );

    } catch (error, stackTrace) {
      _logger.e('❌ Demo OTP send failed', error: error, stackTrace: stackTrace);
      return PhoneVerificationResult.error(
        error: PhoneAuthError.unknown,
        message: 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verify OTP code (demo simulation)
  Future<PhoneVerificationResult> verifyOTP(String verificationId, String otpCode) async {
    try {
      _logger.i('🔐 Demo mode: Verifying OTP code');

      // Check if verification ID matches
      if (_verificationId == null || _verificationId != verificationId) {
        return PhoneVerificationResult.error(
          error: PhoneAuthError.invalidVerificationId,
          message: 'Invalid verification session. Please request a new OTP.',
        );
      }

      // Check attempt limits
      _otpAttempts++;
      if (_otpAttempts > _maxOtpAttempts) {
        return PhoneVerificationResult.error(
          error: PhoneAuthError.sessionExpired,
          message: 'Too many attempts. Please request a new OTP.',
        );
      }

      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if OTP matches demo code
      if (otpCode == _demoOtp) {
        _logger.i('✅ Demo OTP verified successfully');
        
        // Create demo user credential
        final demoCredential = DemoUserCredential(
          user: DemoUser(
            uid: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
            phoneNumber: '+44794036****', // Masked for demo
            isEmailVerified: false,
            creationTime: DateTime.now(),
            lastSignInTime: DateTime.now(),
          ),
        );

        return PhoneVerificationResult.verified(
          credential: demoCredential,
          message: '✅ Phone number verified successfully!',
        );
      } else {
        _logger.w('❌ Demo OTP verification failed: incorrect code');
        return PhoneVerificationResult.error(
          error: PhoneAuthError.invalidVerificationCode,
          message: 'Invalid verification code. Please try again.',
        );
      }

    } catch (error, stackTrace) {
      _logger.e('❌ Demo OTP verification failed', error: error, stackTrace: stackTrace);
      return PhoneVerificationResult.error(
        error: PhoneAuthError.unknown,
        message: 'Verification failed. Please try again.',
      );
    }
  }

  /// Resend OTP (demo simulation)
  Future<PhoneVerificationResult> resendOTP(String phoneNumber) async {
    _logger.i('🔄 Demo mode: Resending OTP');
    return sendOTP(phoneNumber); // Same as send for demo
  }

  /// Sign out (demo simulation)
  Future<void> signOut() async {
    _logger.i('👋 Demo mode: Signing out');
    _verificationId = null;
    _lastOtpSent = null;
    _otpAttempts = 0;
  }

  /// Basic phone number validation
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with + and has at least 10 digits
    return cleaned.startsWith('+') && cleaned.length >= 11 && cleaned.length <= 15;
  }

  /// Mask phone number for logging
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 4) return phoneNumber;
    return '${phoneNumber.substring(0, phoneNumber.length - 4)}****';
  }
}

/// Demo User Credential (replaces Firebase UserCredential)
class DemoUserCredential {
  final DemoUser user;
  
  DemoUserCredential({required this.user});
}

/// Demo User (replaces Firebase User)
class DemoUser {
  final String uid;
  final String? phoneNumber;
  final bool isEmailVerified;
  final DateTime creationTime;
  final DateTime lastSignInTime;

  DemoUser({
    required this.uid,
    this.phoneNumber,
    required this.isEmailVerified,
    required this.creationTime,
    required this.lastSignInTime,
  });
}

/// Phone Verification Result wrapper
class PhoneVerificationResult {
  final bool isSuccess;
  final String? verificationId;
  final DemoUserCredential? credential;
  final PhoneAuthError? error;
  final String message;

  PhoneVerificationResult._({
    required this.isSuccess,
    this.verificationId,
    this.credential,
    this.error,
    required this.message,
  });

  factory PhoneVerificationResult.success({
    required String verificationId,
    required String message,
  }) {
    return PhoneVerificationResult._(
      isSuccess: true,
      verificationId: verificationId,
      message: message,
    );
  }

  factory PhoneVerificationResult.verified({
    required DemoUserCredential credential,
    required String message,
  }) {
    return PhoneVerificationResult._(
      isSuccess: true,
      credential: credential,
      message: message,
    );
  }

  factory PhoneVerificationResult.error({
    required PhoneAuthError error,
    required String message,
  }) {
    return PhoneVerificationResult._(
      isSuccess: false,
      error: error,
      message: message,
    );
  }
}

/// Phone Authentication Error Types
enum PhoneAuthError {
  invalidPhoneNumber,
  invalidVerificationCode,
  invalidVerificationId,
  tooManyRequests,
  sessionExpired,
  networkError,
  operationNotAllowed,
  appNotAuthorized,
  captchaCheckFailed,
  unknown,
} 