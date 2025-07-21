import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Production-level Firebase Authentication Service
/// Handles phone verification with comprehensive security and error handling
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // Verification state tracking
  String? _verificationId;
  int? _resendToken;
  Timer? _timeoutTimer;
  
  // Rate limiting
  DateTime? _lastSendTime;
  int _sendAttempts = 0;
  static const int _maxSendAttempts = 3;
  static const Duration _sendCooldown = Duration(minutes: 1);
  static const Duration _verificationTimeout = Duration(seconds: 120);

  /// Initialize Firebase Authentication
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      // Set language code for SMS
      await _auth.setLanguageCode('en');
      
      _logger.i('Firebase Auth initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to initialize Firebase Auth', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get Firebase configuration options
  /// Note: In production, these should come from environment variables
  FirebaseOptions? _getFirebaseOptions() {
    if (kIsWeb) {
      // Web configuration - replace with your Firebase project config
      return const FirebaseOptions(
        apiKey: "YOUR_WEB_API_KEY",
        authDomain: "your-project.firebaseapp.com",
        projectId: "your-project-id",
        storageBucket: "your-project.appspot.com",
        messagingSenderId: "123456789",
        appId: "1:123456789:web:abcdef123456",
      );
    }
    
    // For mobile platforms, use google-services.json/GoogleService-Info.plist
    return null;
  }

  /// Send OTP to phone number with comprehensive security checks
  Future<PhoneVerificationResult> sendOTP(String phoneNumber) async {
    try {
      // Validate input
      if (!_isValidPhoneNumber(phoneNumber)) {
        return PhoneVerificationResult.error(
          PhoneAuthError.invalidPhoneNumber,
          'Invalid phone number format',
        );
      }

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return PhoneVerificationResult.error(
          PhoneAuthError.networkError,
          'No internet connection. Please check your network and try again.',
        );
      }

      // Rate limiting check
      if (!_canSendOTP()) {
        final remainingTime = _getRemainingCooldownTime();
        return PhoneVerificationResult.error(
          PhoneAuthError.tooManyRequests,
          'Too many attempts. Please wait ${remainingTime.inSeconds} seconds before trying again.',
        );
      }

      // Clean phone number
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      _logger.i('Sending OTP to: ${_maskPhoneNumber(cleanNumber)}');

      final Completer<PhoneVerificationResult> completer = Completer();

      // Set up verification timeout
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(_verificationTimeout, () {
        if (!completer.isCompleted) {
          completer.complete(PhoneVerificationResult.error(
            PhoneAuthError.timeout,
            'Verification timed out. Please try again.',
          ));
        }
      });

      await _auth.verifyPhoneNumber(
        phoneNumber: cleanNumber,
        forceResendingToken: _resendToken,
        
        // Verification completed automatically (rarely happens on web)
        verificationCompleted: (PhoneAuthCredential credential) async {
          _timeoutTimer?.cancel();
          if (!completer.isCompleted) {
            try {
              final userCredential = await _auth.signInWithCredential(credential);
              
              // Check if user exists before using it
              if (userCredential.user != null) {
                completer.complete(PhoneVerificationResult.autoVerified(userCredential.user!));
              } else {
                completer.complete(PhoneVerificationResult.error(
                  PhoneAuthError.verificationFailed,
                  'Authentication completed but user not found.',
                ));
              }
            } catch (error) {
              completer.complete(PhoneVerificationResult.error(
                PhoneAuthError.verificationFailed,
                'Auto-verification failed: ${_getErrorMessage(error)}',
              ));
            }
          }
        },

        // Verification failed
        verificationFailed: (FirebaseAuthException error) {
          _timeoutTimer?.cancel();
          _logger.e('Phone verification failed', error: error);
          
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.error(
              _mapFirebaseErrorCode(error.code),
              _getErrorMessage(error),
            ));
          }
        },

        // Code sent successfully
        codeSent: (String verificationId, int? resendToken) {
          _timeoutTimer?.cancel();
          _verificationId = verificationId;
          _resendToken = resendToken;
          _updateRateLimiting();
          
          _logger.i('OTP sent successfully to: ${_maskPhoneNumber(cleanNumber)}');
          
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.codeSent(verificationId));
          }
        },

        // Timeout occurred
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          // Don't complete here as codeSent should have been called
        },

        timeout: _verificationTimeout,
      );

      return completer.future;
      
    } catch (error, stackTrace) {
      _timeoutTimer?.cancel();
      _logger.e('Unexpected error during OTP send', error: error, stackTrace: stackTrace);
      
      return PhoneVerificationResult.error(
        PhoneAuthError.unknown,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Verify OTP code with security validation
  Future<OTPVerificationResult> verifyOTP(String otpCode) async {
    try {
      if (_verificationId == null) {
        return OTPVerificationResult.error(
          'No verification in progress. Please request a new OTP.',
        );
      }

      // Validate OTP format
      if (!_isValidOTP(otpCode)) {
        return OTPVerificationResult.error(
          'Invalid OTP format. Please enter a 6-digit code.',
        );
      }

      _logger.i('Attempting to verify OTP');

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user exists before using it
      if (userCredential.user != null) {
        _logger.i('OTP verified successfully for user: ${userCredential.user!.uid}');
        
        // Clear verification state
        _clearVerificationState();
        
        return OTPVerificationResult.success(userCredential.user!);
      } else {
        _logger.e('OTP verification completed but user not found');
        return OTPVerificationResult.error(
          'Authentication completed but user not found. Please try again.',
        );
      }
      
    } on FirebaseAuthException catch (error) {
      _logger.e('OTP verification failed', error: error);
      
      return OTPVerificationResult.error(
        _getErrorMessage(error),
      );
    } catch (error, stackTrace) {
      _logger.e('Unexpected error during OTP verification', error: error, stackTrace: stackTrace);
      
      return OTPVerificationResult.error(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Resend OTP with rate limiting
  Future<PhoneVerificationResult> resendOTP(String phoneNumber) async {
    _logger.i('Resending OTP');
    return sendOTP(phoneNumber);
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _clearVerificationState();
      _logger.i('User signed out successfully');
    } catch (error, stackTrace) {
      _logger.e('Error during sign out', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Private helper methods

  bool _isValidPhoneNumber(String phoneNumber) {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(cleanNumber);
  }

  bool _isValidOTP(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }

  String _cleanPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      // Add default country code if none provided (unsafe - should prompt user)
      cleaned = '+1$cleaned'; // Default to US - should be configurable
    }
    return cleaned;
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 4) return phoneNumber;
    final visiblePart = phoneNumber.substring(phoneNumber.length - 4);
    final maskedPart = '*' * (phoneNumber.length - 4);
    return maskedPart + visiblePart;
  }

  bool _canSendOTP() {
    if (_lastSendTime == null) return true;
    
    final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
    
    if (timeSinceLastSend >= _sendCooldown) {
      _sendAttempts = 0; // Reset attempts after cooldown
      return true;
    }
    
    return _sendAttempts < _maxSendAttempts;
  }

  Duration _getRemainingCooldownTime() {
    if (_lastSendTime == null) return Duration.zero;
    
    final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
    final remaining = _sendCooldown - timeSinceLastSend;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _updateRateLimiting() {
    _lastSendTime = DateTime.now();
    _sendAttempts++;
  }

  void _clearVerificationState() {
    _verificationId = null;
    _resendToken = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  PhoneAuthError _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return PhoneAuthError.invalidPhoneNumber;
      case 'too-many-requests':
        return PhoneAuthError.tooManyRequests;
      case 'operation-not-allowed':
        return PhoneAuthError.operationNotAllowed;
      case 'network-request-failed':
        return PhoneAuthError.networkError;
      case 'invalid-verification-code':
        return PhoneAuthError.invalidVerificationCode;
      case 'invalid-verification-id':
        return PhoneAuthError.invalidVerificationId;
      default:
        return PhoneAuthError.unknown;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'The phone number format is invalid. Please enter a valid phone number.';
        case 'too-many-requests':
          return 'Too many requests. Please wait before trying again.';
        case 'operation-not-allowed':
          return 'Phone authentication is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'invalid-verification-code':
          return 'Invalid verification code. Please check the code and try again.';
        case 'invalid-verification-id':
          return 'Verification session expired. Please request a new code.';
        default:
          return error.message ?? 'An unexpected error occurred.';
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Dispose resources
  void dispose() {
    _timeoutTimer?.cancel();
  }
}

// Result classes for type-safe responses

class PhoneVerificationResult {
  final PhoneVerificationStatus status;
  final String? verificationId;
  final User? user;
  final PhoneAuthError? errorType;
  final String? errorMessage;

  PhoneVerificationResult._({
    required this.status,
    this.verificationId,
    this.user,
    this.errorType,
    this.errorMessage,
  });

  factory PhoneVerificationResult.codeSent(String verificationId) {
    return PhoneVerificationResult._(
      status: PhoneVerificationStatus.codeSent,
      verificationId: verificationId,
    );
  }

  factory PhoneVerificationResult.autoVerified(User user) {
    return PhoneVerificationResult._(
      status: PhoneVerificationStatus.autoVerified,
      user: user,
    );
  }

  factory PhoneVerificationResult.error(PhoneAuthError errorType, String message) {
    return PhoneVerificationResult._(
      status: PhoneVerificationStatus.error,
      errorType: errorType,
      errorMessage: message,
    );
  }

  bool get isSuccess => status == PhoneVerificationStatus.codeSent || status == PhoneVerificationStatus.autoVerified;
  bool get isError => status == PhoneVerificationStatus.error;
}

class OTPVerificationResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  OTPVerificationResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory OTPVerificationResult.success(User user) {
    return OTPVerificationResult._(isSuccess: true, user: user);
  }

  factory OTPVerificationResult.error(String message) {
    return OTPVerificationResult._(isSuccess: false, errorMessage: message);
  }
}

// Enums for better type safety

enum PhoneVerificationStatus {
  codeSent,
  autoVerified,
  error,
}

enum PhoneAuthError {
  invalidPhoneNumber,
  tooManyRequests,
  operationNotAllowed,
  networkError,
  invalidVerificationCode,
  invalidVerificationId,
  timeout,
  verificationFailed,
  unknown,
} 