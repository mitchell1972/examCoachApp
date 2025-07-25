import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'app_config.dart';
import 'security_service.dart';

/// Comprehensive error handling service
class ErrorHandler {
  static final Logger _logger = Logger();
  static final Map<String, int> _errorCounts = {};
  static Timer? _errorReportTimer;
  
  /// Initialize error handling service
  static void initialize() {
    _logger.i('Error handler initialized');
    
    // Start periodic error reporting in production
    if (AppConfig.instance.isProduction) {
      _startErrorReporting();
    }
  }
  
  /// Log an error with context and security considerations
  static void logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    try {
      final errorKey = _generateErrorKey(error);
      _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
      
      // Sanitize error data for security
      final sanitizedError = _sanitizeError(error);
      final sanitizedData = _sanitizeAdditionalData(additionalData);
      
      // Log based on severity
      switch (severity) {
        case ErrorSeverity.debug:
          _logger.d('Debug: $sanitizedError', 
                    error: sanitizedError, stackTrace: stackTrace);
          break;
        case ErrorSeverity.info:
          _logger.i('Info: $sanitizedError');
          break;
        case ErrorSeverity.warning:
          _logger.w('Warning: $sanitizedError', 
                    error: sanitizedError, stackTrace: stackTrace);
          break;
        case ErrorSeverity.error:
          _logger.e('Error: $sanitizedError', 
                    error: sanitizedError, stackTrace: stackTrace);
          break;
        case ErrorSeverity.fatal:
          _logger.f('Fatal: $sanitizedError', 
                    error: sanitizedError, stackTrace: stackTrace);
          break;
      }
      
      // Additional logging for production monitoring
      if (AppConfig.instance.isProduction && severity.index >= ErrorSeverity.error.index) {
        _logToProductionMonitoring(sanitizedError, sanitizedData, context, severity);
      }
      
    } catch (loggingError) {
      // Fallback logging if main logging fails
      print('Logging failed: $loggingError - Original error: $error');
    }
  }
  
  /// Generate a unique key for error tracking
  static String _generateErrorKey(dynamic error) {
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();
    final truncatedMessage = errorMessage.length > 50 
        ? errorMessage.substring(0, 50) 
        : errorMessage;
    return '$errorType:$truncatedMessage';
  }
  
  /// Sanitize error data to prevent sensitive information leakage
  static String _sanitizeError(dynamic error) {
    String errorString = error.toString();
    
    // Remove common sensitive patterns
    errorString = _removeSensitivePatterns(errorString);
    
    // Validate input security
    if (!SecurityService.isInputSecure(errorString)) {
      errorString = SecurityService.sanitizeInput(errorString);
    }
    
    return errorString;
  }
  
  /// Sanitize additional data
  static Map<String, dynamic>? _sanitizeAdditionalData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Skip sensitive keys
      if (_isSensitiveKey(key)) {
        sanitized[key] = '[REDACTED]';
        continue;
      }
      
      // Sanitize string values
      if (value is String) {
        sanitized[key] = _removeSensitivePatterns(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Check if a key contains sensitive information
  static bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      'password', 'token', 'secret', 'key', 'auth', 'credential',
      'api_key', 'access_token', 'refresh_token', 'session_id',
      'phone', 'email', 'ssn', 'credit_card', 'bank_account'
    ];
    
    final lowerKey = key.toLowerCase();
    return sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive));
  }
  
  /// Remove sensitive patterns from text
  static String _removeSensitivePatterns(String text) {
    // Remove email addresses
    text = text.replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL]');
    
    // Remove phone numbers
    text = text.replaceAll(RegExp(r'\b\d{3}-?\d{3}-?\d{4}\b'), '[PHONE]');
    
    // Remove potential tokens (long alphanumeric strings)
    text = text.replaceAll(RegExp(r'\b[A-Za-z0-9]{20,}\b'), '[TOKEN]');
    
    // Remove file paths
    text = text.replaceAll(RegExp(r'[A-Za-z]:\\[^\\]+\\'), '[PATH]\\');
    text = text.replaceAll(RegExp(r'/[^/\s]+/[^/\s]+/'), '/[PATH]/');
    
    return text;
  }
  
  /// Log to production monitoring service
  static void _logToProductionMonitoring(
    String error, 
    Map<String, dynamic>? data,
    String? context,
    ErrorSeverity severity,
  ) {
    // This would integrate with services like Sentry, LogRocket, etc.
    // For now, it's a placeholder for production error tracking
    _logger.i('Production monitoring: $severity - $error');
  }
  
  /// Handle different types of exceptions with appropriate user messages
  static ErrorInfo handleException(dynamic exception) {
    if (exception is SocketException) {
      return ErrorInfo(
        userMessage: 'Network connection error. Please check your internet connection.',
        technicalMessage: exception.toString(),
        errorType: ErrorType.network,
        severity: ErrorSeverity.warning,
      );
    }
    
    if (exception is TimeoutException) {
      return ErrorInfo(
        userMessage: 'Request timed out. Please try again.',
        technicalMessage: exception.toString(),
        errorType: ErrorType.timeout,
        severity: ErrorSeverity.warning,
      );
    }
    
    if (exception is FormatException) {
      return ErrorInfo(
        userMessage: 'Invalid data format. Please try again.',
        technicalMessage: exception.toString(),
        errorType: ErrorType.validation,
        severity: ErrorSeverity.error,
      );
    }
    
    if (exception is SecurityException) {
      return ErrorInfo(
        userMessage: 'Security error. Please contact support.',
        technicalMessage: exception.toString(),
        errorType: ErrorType.security,
        severity: ErrorSeverity.fatal,
      );
    }
    
    if (exception is FileSystemException) {
      return ErrorInfo(
        userMessage: 'File system error. Please try again.',
        technicalMessage: exception.toString(),
        errorType: ErrorType.storage,
        severity: ErrorSeverity.error,
      );
    }
    
    // Default handling for unknown exceptions
    return ErrorInfo(
      userMessage: 'An unexpected error occurred. Please try again.',
      technicalMessage: exception.toString(),
      errorType: ErrorType.unknown,
      severity: ErrorSeverity.error,
    );
  }
  
  /// Show user-friendly error dialog
  static void showErrorDialog(BuildContext context, ErrorInfo errorInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            _getErrorIcon(errorInfo.errorType),
            color: _getErrorColor(errorInfo.severity),
            size: 48,
          ),
          title: Text(_getErrorTitle(errorInfo.errorType)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorInfo.userMessage),
              if (AppConfig.instance.isDevelopment && errorInfo.technicalMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Technical Details:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  errorInfo.technicalMessage,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (errorInfo.errorType == ErrorType.network) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Retry logic would go here
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        );
      },
    );
  }
  
  /// Get appropriate icon for error type
  static IconData _getErrorIcon(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.security:
        return Icons.security;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }
  
  /// Get appropriate color for error severity
  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.debug:
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.fatal:
        return Colors.red.shade900;
    }
  }
  
  /// Get appropriate title for error type
  static String _getErrorTitle(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.timeout:
        return 'Timeout Error';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.security:
        return 'Security Error';
      case ErrorType.storage:
        return 'Storage Error';
      case ErrorType.unknown:
        return 'Error';
    }
  }
  
  /// Start periodic error reporting for production
  static void _startErrorReporting() {
    _errorReportTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _reportErrorStatistics();
    });
  }
  
  /// Report error statistics
  static void _reportErrorStatistics() {
    if (_errorCounts.isNotEmpty) {
      _logger.i('Error statistics report: $_errorCounts');
      // Clear counts after reporting
      _errorCounts.clear();
    }
  }
  
  /// Get error count for a specific error
  static int getErrorCount(String errorKey) {
    return _errorCounts[errorKey] ?? 0;
  }
  
  /// Clear all error counts
  static void clearErrorCounts() {
    _errorCounts.clear();
  }
  
  /// Dispose of error handler resources
  static void dispose() {
    _errorReportTimer?.cancel();
    _errorReportTimer = null;
    _errorCounts.clear();
  }
}

/// Error information container
class ErrorInfo {
  final String userMessage;
  final String technicalMessage;
  final ErrorType errorType;
  final ErrorSeverity severity;
  
  const ErrorInfo({
    required this.userMessage,
    required this.technicalMessage,
    required this.errorType,
    required this.severity,
  });
}

/// Error type enumeration
enum ErrorType {
  network,
  timeout,
  validation,
  security,
  storage,
  unknown,
}

/// Error severity enumeration
enum ErrorSeverity {
  debug,
  info,
  warning,
  error,
  fatal,
} 