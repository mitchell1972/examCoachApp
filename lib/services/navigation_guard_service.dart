import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../screens/dashboard_screen.dart';
import '../screens/subscription_screen.dart';
import 'content_access_service.dart';

/// Service to handle navigation logic based on user trial and subscription status
class NavigationGuardService {
  static final NavigationGuardService _instance = NavigationGuardService._internal();
  factory NavigationGuardService() => _instance;
  NavigationGuardService._internal();

  final Logger _logger = Logger();
  final ContentAccessService _contentAccess = ContentAccessService();

  /// Navigate user to appropriate screen based on their access status
  void navigateBasedOnAccess(BuildContext context, UserModel user) {
    _logger.i('🧭 Checking navigation route for user: ${user.email}');
    _logger.i('   Trial expired: ${user.isTrialExpired}');
    _logger.i('   Has subscription: ${user.hasActiveSubscription}');
    _logger.i('   Needs subscription: ${user.needsSubscription}');

    if (user.needsSubscription) {
      _logger.i('🔒 Redirecting to subscription screen - trial expired');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SubscriptionScreen(userModel: user),
        ),
      );
    } else {
      _logger.i('✅ Redirecting to dashboard - access granted');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userModel: user),
        ),
      );
    }
  }

  /// Check if user should be redirected on app startup
  Future<bool> shouldRedirectOnStartup(UserModel user) async {
    _logger.i('🔍 Checking startup redirect for user: ${user.email}');
    
    // Log current status for debugging
    _logger.i('   Current time: ${DateTime.now()}');
    _logger.i('   Trial end time: ${user.trialEndTime}');
    _logger.i('   Trial expired: ${user.isTrialExpired}');
    _logger.i('   Subscription status: ${user.subscriptionStatus}');
    _logger.i('   Subscription end: ${user.subscriptionEndTime}');

    return user.needsSubscription;
  }

  /// Navigate to subscription screen with context
  void navigateToSubscription(BuildContext context, UserModel user, {String? reason}) {
    if (reason != null) {
      _logger.i('🔒 Redirecting to subscription: $reason');
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SubscriptionScreen(userModel: user),
      ),
    );
  }

  /// Navigate to dashboard with context
  void navigateToDashboard(BuildContext context, UserModel user, {String? reason}) {
    if (reason != null) {
      _logger.i('✅ Redirecting to dashboard: $reason');
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(userModel: user),
      ),
    );
  }

  /// Show content locked dialog
  void showContentLockedDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Content Locked',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contentAccess.getContentLockReason(user),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Subscribe for just ₦600/week to unlock all features!',
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToSubscription(context, user, reason: 'Content access required');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }

  /// Check access before performing an action
  bool checkAccessAndShowDialogIfNeeded(
    BuildContext context, 
    UserModel user, 
    String contentType
  ) {
    final hasAccess = _contentAccess.hasContentAccess(user);
    _contentAccess.logContentAccessAttempt(user, contentType, hasAccess);

    if (!hasAccess) {
      showContentLockedDialog(context, user);
      return false;
    }

    return true;
  }

  /// Get navigation route name based on user status
  String getRouteForUser(UserModel user) {
    if (user.needsSubscription) {
      return '/subscription';
    } else {
      return '/dashboard';
    }
  }
}