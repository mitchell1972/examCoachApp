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

  FirebaseAuth? _auth; // Nullable to handle demo mode
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

  bool _initialized = false;
  bool _initFailed = false;
  bool _isDemo = false; // Demo mode flag

  /// Initialize Firebase Authentication
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if we're in a CI environment or demo mode
      final isCI = const String.fromEnvironment('CI', defaultValue: 'false') == 'true';
      final isDemoMode = const String.fromEnvironment('DEMO_MODE', defaultValue: 'false') == 'true';
      
      if (isCI || isDemoMode) {
        _logger.i('Running in demo mode (CI=$isCI, DEMO_MODE=$isDemoMode)');
        _isDemo = true;
        _initialized = true;
        return;
      }

      if (kIsWeb) {
        final options = _getFirebaseOptions();
        if (options != null && options.apiKey != 'YOUR_WEB_API_KEY') {
          await Firebase.initializeApp(options: options);
        } else {
          // Config missing – switch to demo mode
          _logger.w('Firebase Web config missing. Switching to demo mode.');
          _isDemo = true;
          _initialized = true;
          return;
        }
      } else {
        // Mobile/desktop – configuration comes from google-services.json / plist
        await Firebase.initializeApp();
      }

      // If we reach here, Firebase initialized successfully
      _auth = FirebaseAuth.instance;
      await _auth!.setLanguageCode('en');

      _initialized = true;
      _logger.i('Firebase Auth initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to initialize Firebase Auth', error: error, stackTrace: stackTrace);
      _initFailed = true;
      _isDemo = true; // Fall back to demo mode
      _initialized = true;
    }
  }

  /// Get Firebase configuration options
  /// Note: In production, these should come from environment variables
  FirebaseOptions? _getFirebaseOptions() {
    if (kIsWeb) {
      // Web configuration - replace with your Firebase project config
      // These can be public as they're restricted by domain in Firebase Console
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
    // Ensure initialization has been attempted
    if (!_initialized) {
      await initialize();
    }
    
    // Check if we're in demo mode
    if (_isDemo) {
      // Demo mode - simulate OTP sending
      _logger.i('Demo mode: Simulating OTP send to ${_maskPhoneNumber(phoneNumber)}');
      _verificationId = 'demo-verification-id-${DateTime.now().millisecondsSinceEpoch}';
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      return PhoneVerificationResult.success(
        verificationId: _verificationId!,
        message: 'Demo OTP "123456" sent to ${_maskPhoneNumber(phoneNumber)}',
      );
    }
    
    // Real Firebase implementation
    if (_initFailed || _auth == null) {
      return PhoneVerificationResult.error(
        PhoneAuthError.unknown,
        'Firebase not initialized. Please check configuration.',
      );
    }
    
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

      // Rate limiting
      if (!_canSendOTP()) {
        final cooldownRemaining = _sendCooldown.inSeconds - 
            DateTime.now().difference(_lastSendTime!).inSeconds;
        return PhoneVerificationResult.error(
          PhoneAuthError.tooManyRequests,
          'Please wait $cooldownRemaining seconds before trying again',
        );
      }

      // Log attempt (mask phone number for security)
      _logger.i('Attempting to send OTP to ${_maskPhoneNumber(phoneNumber)}');

      // Clear any existing verification state
      _clearVerificationState();

      // Send OTP
      final completer = Completer<PhoneVerificationResult>();
      
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: _verificationTimeout,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.i('Auto-verification completed');
          // Auto-verification (Android only)
          try {
            final userCredential = await _auth!.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(PhoneVerificationResult.autoVerified(
                credential: userCredential,
              ));
            }
          } catch (e) {
            _logger.e('Auto-verification failed', error: e);
            if (!completer.isCompleted) {
              completer.complete(_mapFirebaseError(e));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.e('Verification failed', error: e);
          if (!completer.isCompleted) {
            completer.complete(_mapFirebaseError(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i('OTP sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _lastSendTime = DateTime.now();
          _sendAttempts++;
          
          // Start timeout timer
          _startTimeoutTimer();
          
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.success(
              verificationId: verificationId,
              message: 'OTP sent successfully',
            ));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.i('Auto-retrieval timeout');
          if (!completer.isCompleted) {
            completer.complete(PhoneVerificationResult.success(
              verificationId: verificationId,
              message: 'OTP sent. Please enter the code manually.',
            ));
          }
        },
        forceResendingToken: _resendToken,
      );

      return await completer.future;
    } catch (error, stackTrace) {
      _logger.e('Failed to send OTP', error: error, stackTrace: stackTrace);
      return _mapFirebaseError(error);
    }
  }

  /// Verify OTP code
  Future<PhoneVerificationResult> verifyOTP(String otpCode) async {
    if (_isDemo) {
      // Demo mode - accept "123456" as valid OTP
      _logger.i('Demo mode: Verifying OTP');
      
      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (otpCode == '123456') {
        _clearVerificationState();
        return PhoneVerificationResult.success(
          message: 'Demo verification successful! Welcome to Exam Coach.',
        );
      } else {
        return PhoneVerificationResult.error(
          PhoneAuthError.invalidVerificationCode,
          'Demo mode: Please use OTP "123456"',
        );
      }
    }
    
    if (_initFailed || _auth == null) {
      return PhoneVerificationResult.error(
        PhoneAuthError.unknown,
        'Firebase not initialized',
      );
    }
    
    try {
      // Validate input
      if (!_isValidOTPCode(otpCode)) {
        return PhoneVerificationResult.error(
          PhoneAuthError.invalidVerificationCode,
          'Invalid OTP format. Please enter 6 digits.',
        );
      }

      if (_verificationId == null) {
        return PhoneVerificationResult.error(
          PhoneAuthError.sessionExpired,
          'Verification session expired. Please request a new OTP.',
        );
      }

      _logger.i('Attempting to verify OTP');

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      // Sign in with credential
      final userCredential = await _auth!.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        _logger.i('OTP verification successful');
        _clearVerificationState();
        
        return PhoneVerificationResult.success(
          credential: userCredential,
          message: 'Phone number verified successfully',
        );
      } else {
        throw Exception('Sign in succeeded but user is null');
      }
    } catch (error, stackTrace) {
      _logger.e('Failed to verify OTP', error: error, stackTrace: stackTrace);
      return _mapFirebaseError(error);
    }
  }

  /// Resend OTP
  Future<PhoneVerificationResult> resendOTP(String phoneNumber) async {
    _logger.i('Resending OTP');
    _resendToken = _resendToken; // Preserve resend token
    return await sendOTP(phoneNumber);
  }

  /// Sign out user
  Future<void> signOut() async {
    if (_isDemo) {
      _logger.i('Demo mode: Sign out');
      return;
    }
    
    if (_auth != null) {
      try {
        await _auth!.signOut();
        _logger.i('User signed out successfully');
      } catch (e) {
        _logger.e('Failed to sign out', error: e);
      }
    }
  }

  /// Check if can send OTP (rate limiting)
  bool _canSendOTP() {
    if (_lastSendTime == null) return true;
    
    final timeSinceLastSend = DateTime.now().difference(_lastSendTime!);
    if (timeSinceLastSend < _sendCooldown) return false;
    
    if (_sendAttempts >= _maxSendAttempts && 
        timeSinceLastSend < const Duration(hours: 1)) {
      return false;
    }
    
    return true;
  }

  /// Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // International format: +[country code][number]
    // Must start with + and contain 10-15 digits total
    final regex = RegExp(r'^\+[1-9]\d{9,14}$');
    return regex.hasMatch(phoneNumber);
  }

  /// Validate OTP code format
  bool _isValidOTPCode(String code) {
    // Must be exactly 6 digits
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(code);
  }

  /// Mask phone number for logging
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 8) return '***';
    final prefix = phoneNumber.substring(0, phoneNumber.length - 4);
    return '$prefix****';
  }

  /// Start timeout timer
  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_verificationTimeout, () {
      _logger.i('Verification timeout reached');
      _clearVerificationState();
    });
  }

  /// Clear verification state
  void _clearVerificationState() {
    _verificationId = null;
    _resendToken = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Map Firebase errors to user-friendly messages
  PhoneVerificationResult _mapFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return PhoneVerificationResult.error(
            PhoneAuthError.invalidPhoneNumber,
            'The phone number format is incorrect. Please include country code (e.g., +1234567890)',
          );
        case 'invalid-verification-code':
          return PhoneVerificationResult.error(
            PhoneAuthError.invalidVerificationCode,
            'The verification code is incorrect. Please try again.',
          );
        case 'invalid-verification-id':
          return PhoneVerificationResult.error(
            PhoneAuthError.sessionExpired,
            'The verification session has expired. Please request a new code.',
          );
        case 'too-many-requests':
          return PhoneVerificationResult.error(
            PhoneAuthError.tooManyRequests,
            'Too many attempts. Please try again later.',
          );
        case 'credential-already-in-use':
          return PhoneVerificationResult.error(
            PhoneAuthError.credentialAlreadyInUse,
            'This phone number is already associated with another account.',
          );
        case 'operation-not-allowed':
          return PhoneVerificationResult.error(
            PhoneAuthError.operationNotAllowed,
            'Phone authentication is not enabled. Please contact support.',
          );
        case 'network-request-failed':
          return PhoneVerificationResult.error(
            PhoneAuthError.networkError,
            'Network error. Please check your internet connection.',
          );
        case 'app-not-authorized':
          return PhoneVerificationResult.error(
            PhoneAuthError.appNotAuthorized,
            'This app is not authorized to use Firebase Authentication.',
          );
        case 'captcha-check-failed':
          return PhoneVerificationResult.error(
            PhoneAuthError.captchaCheckFailed,
            'reCAPTCHA verification failed. Please try again.',
          );
        default:
          return PhoneVerificationResult.error(
            PhoneAuthError.unknown,
            'An error occurred: ${error.message}',
          );
      }
    }
    
    return PhoneVerificationResult.error(
      PhoneAuthError.unknown,
      'An unexpected error occurred. Please try again.',
    );
  }
}

// Result classes and enums
class PhoneVerificationResult {
  final bool isSuccess;
  final String? verificationId;
  final String message;
  final PhoneAuthError? error;
  final UserCredential? credential;

  PhoneVerificationResult._({
    required this.isSuccess,
    this.verificationId,
    required this.message,
    this.error,
    this.credential,
  });

  factory PhoneVerificationResult.success({
    String? verificationId,
    required String message,
    UserCredential? credential,
  }) {
    return PhoneVerificationResult._(
      isSuccess: true,
      verificationId: verificationId,
      message: message,
      credential: credential,
    );
  }

  factory PhoneVerificationResult.autoVerified({
    required UserCredential credential,
  }) {
    return PhoneVerificationResult._(
      isSuccess: true,
      message: 'Auto-verified successfully',
      credential: credential,
    );
  }

  factory PhoneVerificationResult.error(
    PhoneAuthError error,
    String message,
  ) {
    return PhoneVerificationResult._(
      isSuccess: false,
      message: message,
      error: error,
    );
  }
}

enum PhoneAuthError {
  invalidPhoneNumber,
  invalidVerificationCode,
  sessionExpired,
  tooManyRequests,
  credentialAlreadyInUse,
  operationNotAllowed,
  networkError,
  appNotAuthorized,
  captchaCheckFailed,
  unknown,
} 