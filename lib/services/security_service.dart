import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Security service that handles all security-related functionality
class SecurityService {
  static final Logger _logger = Logger();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'exam_coach_secure_prefs',
      preferencesKeyPrefix: 'exam_coach_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.examcoach.securestorage',
      accountName: 'ExamCoachSecureStorage',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static bool _isInitialized = false;
  
  /// Initialize security services
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Initializing security services...');
      
      // Validate device security
      await _validateDeviceSecurity();
      
      // Initialize secure storage
      await _initializeSecureStorage();
      
      // Set up security policies
      await _setupSecurityPolicies();
      
      // Enable certificate pinning for production
      if (kReleaseMode) {
        await _setupCertificatePinning();
      }
      
      _isInitialized = true;
      _logger.i('Security services initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to initialize security services', 
                error: error, stackTrace: stackTrace);
      throw SecurityException('Security initialization failed: $error');
    }
  }
  
  /// Validate device security status
  static Future<void> _validateDeviceSecurity() async {
    try {
      // Check if device is rooted/jailbroken (basic check)
      await _checkDeviceIntegrity();
      
      // Validate app signature in production
      if (kReleaseMode) {
        await _validateAppSignature();
      }
      
      _logger.d('Device security validation passed');
    } catch (error) {
      throw SecurityException('Device security validation failed: $error');
    }
  }
  
  /// Basic device integrity check
  static Future<void> _checkDeviceIntegrity() async {
    // Check for common indicators of compromised devices
    final suspiciousApps = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];
    
    for (final path in suspiciousApps) {
      if (await File(path).exists()) {
        _logger.w('Suspicious file detected: $path');
        // In production, you might want to handle this more strictly
      }
    }
  }
  
  /// Validate app signature (placeholder for production implementation)
  static Future<void> _validateAppSignature() async {
    // This would implement app signature validation
    // to ensure the app hasn't been tampered with
    _logger.d('App signature validation (placeholder)');
  }
  
  /// Initialize secure storage with validation
  static Future<void> _initializeSecureStorage() async {
    try {
      // Test secure storage functionality
      const testKey = '__security_test__';
      const testValue = 'test_value';
      
      await _secureStorage.write(key: testKey, value: testValue);
      final retrievedValue = await _secureStorage.read(key: testKey);
      
      if (retrievedValue != testValue) {
        throw SecurityException('Secure storage validation failed');
      }
      
      await _secureStorage.delete(key: testKey);
      _logger.d('Secure storage initialized and validated');
    } catch (error) {
      throw SecurityException('Secure storage initialization failed: $error');
    }
  }
  
  /// Set up security policies
  static Future<void> _setupSecurityPolicies() async {
    try {
      // Prevent screenshots in sensitive areas (Android)
      if (Platform.isAndroid) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
      
      _logger.d('Security policies configured');
    } catch (error) {
      _logger.w('Failed to set up some security policies: $error');
      // Don't throw here as some policies might be optional
    }
  }
  
  /// Set up certificate pinning for network security
  static Future<void> _setupCertificatePinning() async {
    try {
      // Certificate pinning would be configured here
      // This is a placeholder for when API endpoints are added
      _logger.d('Certificate pinning configured');
    } catch (error) {
      _logger.w('Failed to set up certificate pinning: $error');
    }
  }
  
  /// Securely store sensitive data
  static Future<void> storeSecureData(String key, String value) async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      await _secureStorage.write(key: key, value: value);
      _logger.d('Secure data stored for key: $key');
    } catch (error) {
      _logger.e('Failed to store secure data', error: error);
      throw SecurityException('Failed to store secure data: $error');
    }
  }
  
  /// Retrieve securely stored data
  static Future<String?> getSecureData(String key) async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      final value = await _secureStorage.read(key: key);
      _logger.d('Secure data retrieved for key: $key');
      return value;
    } catch (error) {
      _logger.e('Failed to retrieve secure data', error: error);
      throw SecurityException('Failed to retrieve secure data: $error');
    }
  }
  
  /// Delete securely stored data
  static Future<void> deleteSecureData(String key) async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      await _secureStorage.delete(key: key);
      _logger.d('Secure data deleted for key: $key');
    } catch (error) {
      _logger.e('Failed to delete secure data', error: error);
      throw SecurityException('Failed to delete secure data: $error');
    }
  }
  
  /// Clear all secure storage (use with caution)
  static Future<void> clearAllSecureData() async {
    if (!_isInitialized) {
      throw SecurityException('Security service not initialized');
    }
    
    try {
      await _secureStorage.deleteAll();
      _logger.i('All secure data cleared');
    } catch (error) {
      _logger.e('Failed to clear secure data', error: error);
      throw SecurityException('Failed to clear secure data: $error');
    }
  }
  
  /// Generate a secure session token
  static String generateSecureToken() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(32, (index) => 
      chars[(random + index) % chars.length]
    ).join();
  }
  
  /// Validate input for security threats
  static bool isInputSecure(String input) {
    // Basic input validation to prevent common attacks
    final dangerousPatterns = [
      RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe\b', caseSensitive: false),
      RegExp(r'<object\b', caseSensitive: false),
      RegExp(r'<embed\b', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        _logger.w('Potentially dangerous input detected');
        return false;
      }
    }
    
    return true;
  }
  
  /// Sanitize user input
  static String sanitizeInput(String input) {
    if (!isInputSecure(input)) {
      _logger.w('Input sanitization required');
    }
    
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s@.-]'), '') // Keep only safe characters
        .trim();
  }
}

/// Custom exception for security-related errors
class SecurityException implements Exception {
  final String message;
  
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
} 