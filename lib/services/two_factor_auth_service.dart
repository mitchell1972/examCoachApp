import 'package:logger/logger.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'database_service_rest.dart';
import '../main.dart';

/// Authentication states
enum AuthState {
  initial,           // Not authenticated
  passwordVerified,  // Email/password verified, awaiting SMS
  fullyAuthenticated // Both password and SMS verified
}

/// Two-factor authentication service that implements:
/// 1. Email/Password authentication first
/// 2. SMS OTP verification second (sent to registered phone number)
class TwoFactorAuthService {
  static final TwoFactorAuthService _instance = TwoFactorAuthService._internal();
  factory TwoFactorAuthService() => _instance;
  TwoFactorAuthService._internal();

  final Logger _logger = Logger();
  final StorageService _storageService = StorageService();
  final DatabaseServiceRest _databaseService = DatabaseServiceRest();

  AuthState _currentState = AuthState.initial;
  UserModel? _authenticatingUser;
  DateTime? _passwordVerificationTime;

  /// Get current authentication state
  AuthState get currentState => _currentState;
  UserModel? get authenticatingUser => _authenticatingUser;

  /// Reset authentication state
  void reset() {
    _currentState = AuthState.initial;
    _authenticatingUser = null;
    _passwordVerificationTime = null;
    _logger.i('🔄 Authentication state reset');
  }

  /// Step 1: Verify email and password
  /// Returns true if email/password is valid
  Future<bool> verifyEmailPassword(String email, String password) async {
    try {
      _logger.i('🔐 Attempting email/password verification for: $email');
      
      // Get user by email
      final user = await _getUserByEmail(email);
      if (user == null) {
        _logger.w('❌ No user found with email: $email');
        return false;
      }

      // Verify password
      if (!user.verifyPassword(password)) {
        _logger.w('❌ Invalid password for user: $email');
        return false;
      }

      // Password verified - move to next state
      _currentState = AuthState.passwordVerified;
      _authenticatingUser = user;
      _passwordVerificationTime = DateTime.now();
      
      _logger.i('✅ Email/password verification successful for: $email');
      return true;
    } catch (e) {
      _logger.e('❌ Email/password verification error: $e');
      reset();
      return false;
    }
  }

  /// Step 2: Send SMS OTP to registered phone number
  /// Can only be called after successful email/password verification
  Future<bool> sendSmsOtp() async {
    if (_currentState != AuthState.passwordVerified || _authenticatingUser == null) {
      _logger.w('❌ Cannot send SMS - email/password not verified first');
      return false;
    }

    // Check if password verification is still valid (5 minutes timeout)
    if (_passwordVerificationTime != null && 
        DateTime.now().difference(_passwordVerificationTime!).inMinutes > 5) {
      _logger.w('❌ Password verification expired - please authenticate again');
      reset();
      return false;
    }

    try {
      final phoneNumber = _authenticatingUser!.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        _logger.e('❌ No phone number found for user');
        return false;
      }

      _logger.i('📱 Sending SMS OTP to: $phoneNumber');
      
      // Send OTP using existing auth service
      await authService.sendOTP(phoneNumber);
      
      _logger.i('✅ SMS OTP sent successfully to: $phoneNumber');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to send SMS OTP: $e');
      return false;
    }
  }

  /// Step 3: Verify SMS OTP
  /// Completes the two-factor authentication process
  Future<bool> verifySmsOtp(String otpCode) async {
    if (_currentState != AuthState.passwordVerified || _authenticatingUser == null) {
      _logger.w('❌ Cannot verify SMS - email/password not verified first');
      return false;
    }

    try {
      _logger.i('📱 Verifying SMS OTP code');
      
      final phoneNumber = _authenticatingUser!.phoneNumber!;
      
      // Verify OTP using existing auth service
      final verifiedUser = await authService.verifyOTP(phoneNumber, otpCode);
      final isValid = verifiedUser != null;
      
      if (isValid) {
        // Update user's last login date
        _authenticatingUser!.lastLoginDate = DateTime.now();
        await _storageService.updateUser(_authenticatingUser!);
        
        // Move to fully authenticated state
        _currentState = AuthState.fullyAuthenticated;
        
        _logger.i('✅ Two-factor authentication completed successfully');
        return true;
      } else {
        _logger.w('❌ Invalid SMS OTP code');
        return false;
      }
    } catch (e) {
      _logger.e('❌ SMS OTP verification error: $e');
      return false;
    }
  }

  /// Complete authentication process and return authenticated user
  /// Can only be called after successful two-factor authentication
  UserModel? completeAuthentication() {
    if (_currentState != AuthState.fullyAuthenticated || _authenticatingUser == null) {
      _logger.w('❌ Cannot complete authentication - two-factor auth not completed');
      return null;
    }

    final user = _authenticatingUser!;
    reset(); // Clear authentication state
    
    _logger.i('🎉 Authentication completed for user: ${user.email}');
    return user;
  }

  /// Get user by email address
  Future<UserModel?> _getUserByEmail(String email) async {
    try {
      _logger.i('🔍 Looking up user by email: $email');
      
      // First try database service (for production)
      try {
        final user = await _databaseService.getUserByEmail(email);
        if (user != null) {
          _logger.i('✅ User found in database by email');
          return user;
        }
      } catch (e) {
        _logger.w('⚠️ Database lookup failed, falling back to storage: $e');
      }
      
      // Fallback to storage service (for local development)
      final registeredUser = await _storageService.getRegisteredUser();
      if (registeredUser != null && registeredUser.email == email) {
        _logger.i('✅ User found in local storage by email');
        return registeredUser;
      }
      
      _logger.w('❌ No user found with email: $email');
      return null;
    } catch (e) {
      _logger.e('❌ Error getting user by email: $e');
      return null;
    }
  }

  /// Check if current authentication session is valid
  bool isSessionValid() {
    if (_currentState == AuthState.initial) {
      return false;
    }
    
    if (_passwordVerificationTime != null && 
        DateTime.now().difference(_passwordVerificationTime!).inMinutes > 5) {
      _logger.w('⏰ Authentication session expired');
      reset();
      return false;
    }
    
    return true;
  }

  /// Get remaining time for current authentication session
  Duration? get sessionTimeRemaining {
    if (_passwordVerificationTime == null) return null;
    
    final elapsed = DateTime.now().difference(_passwordVerificationTime!);
    final remaining = Duration(minutes: 5) - elapsed;
    
    return remaining.isNegative ? null : remaining;
  }
} 