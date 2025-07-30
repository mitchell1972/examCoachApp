import 'package:logger/logger.dart';
import '../models/user_model.dart';

/// Service to manage content access based on trial and subscription status
class ContentAccessService {
  static final ContentAccessService _instance = ContentAccessService._internal();
  factory ContentAccessService() => _instance;
  ContentAccessService._internal();

  final Logger _logger = Logger();

  /// Check if user has access to premium content
  bool hasContentAccess(UserModel user) {
    final hasAccess = user.hasAccessToContent;
    _logger.i('🔒 Content access check: $hasAccess for user ${user.email}');
    return hasAccess;
  }

  /// Check if user needs to subscribe
  bool needsSubscription(UserModel user) {
    final needs = user.needsSubscription;
    _logger.i('💳 Subscription needed: $needs for user ${user.email}');
    return needs;
  }

  /// Get user's access status message
  String getAccessStatusMessage(UserModel user) {
    return user.accessStatusMessage;
  }

  /// Check if user can access quiz content
  bool canAccessQuiz(UserModel user, {String? quizType}) {
    if (!hasContentAccess(user)) {
      _logger.w('🚫 Quiz access denied for user ${user.email} - trial expired');
      return false;
    }

    _logger.i('✅ Quiz access granted for user ${user.email}');
    return true;
  }

  /// Check if user can access study materials
  bool canAccessStudyMaterials(UserModel user) {
    if (!hasContentAccess(user)) {
      _logger.w('🚫 Study materials access denied for user ${user.email}');
      return false;
    }

    _logger.i('✅ Study materials access granted for user ${user.email}');
    return true;
  }

  /// Check if user can access performance analytics
  bool canAccessAnalytics(UserModel user) {
    if (!hasContentAccess(user)) {
      _logger.w('🚫 Analytics access denied for user ${user.email}');
      return false;
    }

    _logger.i('✅ Analytics access granted for user ${user.email}');
    return true;
  }

  /// Get content lock reason
  String getContentLockReason(UserModel user) {
    if (user.isTrialExpired && !user.hasActiveSubscription) {
      return 'Your free trial has expired. Subscribe to access premium content.';
    } else if (!user.isOnTrial && !user.hasActiveSubscription) {
      return 'You need an active subscription to access this content.';
    } else {
      return 'Content access restricted.';
    }
  }

  /// Get features available in trial vs subscription
  Map<String, bool> getFeatureAccess(UserModel user) {
    final hasAccess = hasContentAccess(user);
    
    return {
      'basic_quizzes': hasAccess,
      'advanced_quizzes': hasAccess,
      'study_materials': hasAccess,
      'performance_analytics': hasAccess,
      'offline_access': hasAccess && user.hasActiveSubscription,
      'unlimited_attempts': hasAccess,
      'expert_explanations': hasAccess,
      'personalized_plans': hasAccess && user.hasActiveSubscription,
      'achievement_badges': hasAccess,
      'progress_tracking': hasAccess,
    };
  }

  /// Check if specific feature is available
  bool isFeatureAvailable(UserModel user, String feature) {
    final features = getFeatureAccess(user);
    return features[feature] ?? false;
  }

  /// Get trial time remaining as human readable string
  String? getTrialTimeRemainingText(UserModel user) {
    if (!user.isOnTrial) return null;

    final remaining = user.trialTimeRemaining;
    if (remaining == null) return null;

    if (remaining.inHours > 24) {
      final days = remaining.inDays;
      return '$days day${days > 1 ? 's' : ''} remaining';
    } else if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} remaining';
    } else {
      final minutes = remaining.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} remaining';
    }
  }

  /// Log content access attempt for analytics
  void logContentAccessAttempt(UserModel user, String contentType, bool granted) {
    _logger.i(
      '📊 Content access: $contentType - ${granted ? 'GRANTED' : 'DENIED'} '
      'for user ${user.email} (Trial: ${user.isOnTrial}, '
      'Subscription: ${user.hasActiveSubscription})'
    );
  }
}