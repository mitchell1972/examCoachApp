import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// Environment-aware Authentication Service
/// - Production (CI/CD): Real Firebase Authentication
/// - Development: Demo mode simulation
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // Environment detection
  bool get _isProduction => kReleaseMode || _isCI;
  bool get _isCI => const bool.fromEnvironment('CI', defaultValue: false);

  // Demo state tracking (for local development)
  String? _verificationId;
  DateTime? _lastOtpSent;
  int _otpAttempts = 0;
  static const int _maxOtpAttempts = 3;
  static const Duration _otpCooldown = Duration(minutes: 1);
  static const String _demoOtp = '123456';

  /// Initialize the authentication service
  Future<void> initialize() async {
    try {
      if (_isProduction) {
        _logger.i('🔥 Production: Initializing Firebase Authentication...');
        // TODO: Initialize real Firebase
        await _initializeFirebase();
        _logger.i('✅ Firebase Authentication initialized successfully');
      } else {
        _logger.i('🎭 Development: Using Demo Authentication...');
        _logger.i('ℹ️  NO REAL SMS WILL BE SENT - Use demo code: $_demoOtp');
        await Future.delayed(const Duration(milliseconds: 500));
        _logger.i('✅ Demo Auth Service: Initialized successfully');
      }
    } catch (error, stackTrace) {
      final mode = _isProduction ? 'Firebase' : 'Demo';
      _logger.e('❌ $mode service initialization failed', error: error, stackTrace: stackTrace);
      // Continue with app launch even if auth fails (graceful degradation)
    }
  }

  /// Initialize real Firebase (production only)
  Future<void> _initializeFirebase() async {
    if (!_isProduction) return;
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _logger.i('🔥 Firebase Core initialized successfully');
    } catch (error) {
      _logger.w('⚠️  Firebase initialization failed (expected with placeholder config): $error');
      _logger.i('ℹ️  To use real Firebase: Replace placeholder values in lib/firebase_options.dart');
      
      // Don't throw - allow app to continue with fallback behavior
    }
  }

  /// Send OTP to phone number
  Future<PhoneVerificationResult> sendOTP(String phoneNumber) async {
    if (_isProduction) {
      return _sendRealOTP(phoneNumber);
    } else {
      return _sendDemoOTP(phoneNumber);
    }
  }

  /// Send real OTP (production)
  Future<PhoneVerificationResult> _sendRealOTP(String phoneNumber) async {
    try {
      _logger.i('🔥 Production: Sending real OTP to ${_maskPhoneNumber(phoneNumber)}');
      
      final auth = FirebaseAuth.instance;
      final completer = Completer<PhoneVerificationResult>();
      
      // RecaptchaVerifier is for web only
      if (!kIsWeb) {
        throw UnsupportedError('reCAPTCHA is only supported on web.');
      }

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.i('🔥 Auto-verification completed');
          try {
            final userCredential = await auth.signInWithCredential(credential);
            completer.complete(PhoneVerificationResult.verified(
              credential: _createUserCredential(userCredential),
              message: '✅ Phone number verified automatically!',
            ));
          } catch (error) {
            completer.complete(PhoneVerificationResult.error(
              error: PhoneAuthError.unknown,
              message: 'Auto-verification failed: $error',
            ));
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          _logger.e('🔥 Verification failed: ${error.message}');
          final authError = _mapFirebaseError(error);
          completer.complete(PhoneVerificationResult.error(
            error: authError,
            message: error.message ?? 'Verification failed',
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i('🔥 OTP code sent successfully');
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.success(
              verificationId: verificationId,
              message: '📱 OTP sent to $phoneNumber\nEnter the 6-digit code to verify',
            ));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.i('🔥 Auto-retrieval timeout');
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.success(
              verificationId: verificationId,
              message: '📱 OTP sent to $phoneNumber\nEnter the 6-digit code to verify',
            ));
          }
        },
        timeout: const Duration(seconds: 60),
        // FIX: The RecaptchaVerifier is now created and managed internally
        // by the plugin on web. We don't need to create it manually.
        // The plugin will automatically handle reCAPTCHA.
      );
      
      return await completer.future;
      
    } catch (error, stackTrace) {
      _logger.e('❌ Real OTP send failed', error: error, stackTrace: stackTrace);
      return PhoneVerificationResult.error(
        error: PhoneAuthError.unknown,
        message: 'Failed to send OTP: $error',
      );
    }
  }

  /// Send demo OTP (development)
  Future<PhoneVerificationResult> _sendDemoOTP(String phoneNumber) async {
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

      // Validate phone number format
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
        message: '🎭 DEMO MODE: No real SMS sent!\n📱 Use demo code: $_demoOtp\n\n(In production, real OTP would be sent to $phoneNumber)',
      );

    } catch (error, stackTrace) {
      _logger.e('❌ Demo OTP send failed', error: error, stackTrace: stackTrace);
      return PhoneVerificationResult.error(
        error: PhoneAuthError.unknown,
        message: 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verify OTP code
  Future<PhoneVerificationResult> verifyOTP(String verificationId, String otpCode) async {
    if (_isProduction) {
      return _verifyRealOTP(verificationId, otpCode);
    } else {
      return _verifyDemoOTP(verificationId, otpCode);
    }
  }

  /// Verify real OTP (production)
  Future<PhoneVerificationResult> _verifyRealOTP(String verificationId, String otpCode) async {
    try {
      _logger.i('🔥 Production: Verifying real OTP');
      
      final auth = FirebaseAuth.instance;
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      
      final userCredential = await auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        _logger.i('🔥 Real OTP verified successfully');
        return PhoneVerificationResult.verified(
          credential: _createUserCredential(userCredential),
          message: '✅ Phone number verified successfully!',
        );
      } else {
        return PhoneVerificationResult.error(
          error: PhoneAuthError.unknown,
          message: 'Verification completed but user is null',
        );
      }
      
    } catch (error, stackTrace) {
      _logger.e('❌ Real OTP verification failed', error: error, stackTrace: stackTrace);
      
      PhoneAuthError authError = PhoneAuthError.unknown;
      String message = 'Verification failed. Please try again.';
      
      if (error is FirebaseAuthException) {
        authError = _mapFirebaseError(error);
        message = error.message ?? message;
      }
      
      return PhoneVerificationResult.error(
        error: authError,
        message: message,
      );
    }
  }

  /// Verify demo OTP (development)
  Future<PhoneVerificationResult> _verifyDemoOTP(String verificationId, String otpCode) async {
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
          message: '✅ Demo verification successful!\n🎭 In production: Real phone verification completed',
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

  /// Resend OTP
  Future<PhoneVerificationResult> resendOTP(String phoneNumber) async {
    _logger.i('🔄 Resending OTP in ${_isProduction ? 'production' : 'demo'} mode');
    return sendOTP(phoneNumber);
  }

  /// Sign out
  Future<void> signOut() async {
    _logger.i('👋 Signing out in ${_isProduction ? 'production' : 'demo'} mode');
    
    if (_isProduction) {
      await FirebaseAuth.instance.signOut();
    } else {
      // Reset demo state
      _verificationId = null;
      _lastOtpSent = null;
      _otpAttempts = 0;
    }
  }

  /// Create DemoUserCredential from Firebase UserCredential
  DemoUserCredential _createUserCredential(UserCredential userCredential) {
    final user = userCredential.user!;
    return DemoUserCredential(
      user: DemoUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        isEmailVerified: user.emailVerified,
        creationTime: user.metadata.creationTime ?? DateTime.now(),
        lastSignInTime: user.metadata.lastSignInTime ?? DateTime.now(),
      ),
    );
  }

  /// Map Firebase errors to our custom error enum
  PhoneAuthError _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return PhoneAuthError.invalidPhoneNumber;
      case 'invalid-verification-code':
        return PhoneAuthError.invalidVerificationCode;
      case 'invalid-verification-id':
        return PhoneAuthError.invalidVerificationId;
      case 'too-many-requests':
        return PhoneAuthError.tooManyRequests;
      case 'session-expired':
        return PhoneAuthError.sessionExpired;
      case 'network-request-failed':
        return PhoneAuthError.networkError;
      case 'operation-not-allowed':
        return PhoneAuthError.operationNotAllowed;
      case 'app-not-authorized':
        return PhoneAuthError.appNotAuthorized;
      case 'captcha-check-failed':
        return PhoneAuthError.captchaCheckFailed;
      default:
        return PhoneAuthError.unknown;
    }
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

/// Demo User Credential (replaces any auth UserCredential)
class DemoUserCredential {
  final DemoUser user;
  
  DemoUserCredential({required this.user});
}

/// Demo User (replaces any auth User)
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