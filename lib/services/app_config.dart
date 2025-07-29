import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application configuration service
class AppConfig extends ChangeNotifier {
  static final Logger _logger = Logger();
  static AppConfig? _instance;
  static bool _isInitialized = false;
  
  // App Configuration
  late final String _appName;
  late final String _appVersion;
  late final String _buildNumber;
  late final Environment _environment;
  
  // Feature Flags
  bool _isDarkModeEnabled = true;
  bool _isAnalyticsEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isPushNotificationsEnabled = true;
  
  // Security Configuration
  late final int _sessionTimeoutMinutes;
  late final int _maxLoginAttempts;
  late final bool _requireBiometric;
  
  // Private constructor
  AppConfig._internal();
  
  /// Get singleton instance
  static AppConfig get instance {
    return _instance ??= AppConfig._internal();
  }
  
  /// Initialize application configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Initializing app configuration...');
      
      final config = AppConfig.instance;
      await config._loadConfiguration();
      
      _isInitialized = true;
      _logger.i('App configuration initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to initialize app configuration', 
                error: error, stackTrace: stackTrace);
      throw ConfigurationException('App configuration initialization failed: $error');
    }
  }
  
  /// Load configuration based on environment
  Future<void> _loadConfiguration() async {
    try {
      // Determine environment
      _environment = _determineEnvironment();
      
      // Load basic app info
      _appName = 'Exam Coach';
      _appVersion = '1.0.0';
      _buildNumber = '1';
      
      // Load environment-specific configuration
      switch (_environment) {
        case Environment.development:
          await _loadDevelopmentConfig();
          break;
        case Environment.staging:
          await _loadStagingConfig();
          break;
        case Environment.production:
          await _loadProductionConfig();
          break;
      }
      
      _logger.d('Configuration loaded for environment: ${_environment.name}');
    } catch (error) {
      throw ConfigurationException('Failed to load configuration: $error');
    }
  }
  
  /// Determine current environment
  Environment _determineEnvironment() {
    // Force development mode for demo purposes
    // In a real app, you'd use proper environment detection
    if (kDebugMode || kProfileMode) {
      return Environment.development;
    } else {
      // For demo purposes, default to development even in release mode
      // In production, you'd want this to be Environment.production
      return Environment.development; 
    }
  }
  
  /// Load development environment configuration
  Future<void> _loadDevelopmentConfig() async {
    _sessionTimeoutMinutes = 30; // Longer session for development
    _maxLoginAttempts = 10; // More lenient for testing
    _requireBiometric = false; // Optional in dev
    _isAnalyticsEnabled = false; // Disabled in dev
  }
  
  /// Load staging environment configuration
  Future<void> _loadStagingConfig() async {
    _sessionTimeoutMinutes = 15;
    _maxLoginAttempts = 5;
    _requireBiometric = false; // Optional in staging
    _isAnalyticsEnabled = true; // Enabled for testing
  }
  
  /// Load production environment configuration
  Future<void> _loadProductionConfig() async {
    _sessionTimeoutMinutes = 10; // Shorter for security
    _maxLoginAttempts = 3; // Strict in production
    _requireBiometric = true; // Required in production
    _isAnalyticsEnabled = true; // Enabled in production
  }
  
  // Getters for app information
  String get appName => _appName;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;
  Environment get environment => _environment;
  
  // Getters for feature flags
  bool get isDarkModeEnabled => _isDarkModeEnabled;
  bool get isAnalyticsEnabled => _isAnalyticsEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isPushNotificationsEnabled => _isPushNotificationsEnabled;
  
  // Getters for security configuration
  int get sessionTimeoutMinutes => _sessionTimeoutMinutes;
  int get maxLoginAttempts => _maxLoginAttempts;
  bool get requireBiometric => _requireBiometric;
  
  // Computed properties
  bool get isDevelopment => _environment == Environment.development;
  bool get isProduction => _environment == Environment.production;
  bool get isStaging => _environment == Environment.staging;
  
  Duration get sessionTimeout => Duration(minutes: _sessionTimeoutMinutes);
  
  String get appDisplayName {
    if (isDevelopment) return '$_appName (Dev)';
    if (isStaging) return '$_appName (Staging)';
    return _appName;
  }
  
  /// Update dark mode setting
  Future<void> setDarkModeEnabled(bool enabled) async {
    if (_isDarkModeEnabled != enabled) {
      _isDarkModeEnabled = enabled;
      notifyListeners();
      _logger.d('Dark mode ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Update analytics setting
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (_isAnalyticsEnabled != enabled) {
      _isAnalyticsEnabled = enabled;
      notifyListeners();
      _logger.d('Analytics ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Update biometric setting
  Future<void> setBiometricEnabled(bool enabled) async {
    if (_isBiometricEnabled != enabled) {
      _isBiometricEnabled = enabled;
      notifyListeners();
      _logger.d('Biometric authentication ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Update push notifications setting
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    if (_isPushNotificationsEnabled != enabled) {
      _isPushNotificationsEnabled = enabled;
      notifyListeners();
      _logger.d('Push notifications ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Get API base URL based on environment
  String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://dev-api.examcoach.com';
      case Environment.staging:
        return 'https://staging-api.examcoach.com';
      case Environment.production:
        return 'https://api.examcoach.com';
    }
  }
  
  /// Get websocket URL based on environment
  String get websocketUrl {
    switch (_environment) {
      case Environment.development:
        return 'wss://dev-ws.examcoach.com';
      case Environment.staging:
        return 'wss://staging-ws.examcoach.com';
      case Environment.production:
        return 'wss://ws.examcoach.com';
    }
  }
  
  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'darkmode':
        return _isDarkModeEnabled;
      case 'analytics':
        return _isAnalyticsEnabled;
      case 'biometric':
        return _isBiometricEnabled;
      case 'pushnotifications':
        return _isPushNotificationsEnabled;
      default:
        _logger.w('Unknown feature flag: $featureName');
        return false;
    }
  }
  
  /// Get configuration as map for debugging
  Map<String, dynamic> toMap() {
    return {
      'appName': _appName,
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'environment': _environment.name,
      'sessionTimeoutMinutes': _sessionTimeoutMinutes,
      'maxLoginAttempts': _maxLoginAttempts,
      'requireBiometric': _requireBiometric,
      'isDarkModeEnabled': _isDarkModeEnabled,
      'isAnalyticsEnabled': _isAnalyticsEnabled,
      'isBiometricEnabled': _isBiometricEnabled,
      'isPushNotificationsEnabled': _isPushNotificationsEnabled,
      'apiBaseUrl': apiBaseUrl,
      'websocketUrl': websocketUrl,
    };
  }
  
  /// Print configuration for debugging (only in development)
  void debugPrintConfig() {
    if (isDevelopment) {
      _logger.d('App Configuration:');
      toMap().forEach((key, value) {
        _logger.d('  $key: $value');
      });
    }
  }
}

/// Application environment enumeration
enum Environment {
  development,
  staging,
  production,
}

/// Custom exception for configuration errors
class ConfigurationException implements Exception {
  final String message;
  
  const ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
} 