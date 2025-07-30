import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../models/payment_models.dart';
import 'storage_service.dart';
import 'database_service_rest.dart';

/// Service for handling Paystack webhook events
class WebhookService {
  static final WebhookService _instance = WebhookService._internal();
  factory WebhookService() => _instance;
  WebhookService._internal();

  final Logger _logger = Logger();
  final StorageService _storageService = StorageService();
  final DatabaseServiceRest _databaseService = DatabaseServiceRest();
  
  // Paystack webhook secret for verification
  static const String _webhookSecret = 'your_webhook_secret_here'; // Replace with actual secret

  /// Verify webhook signature from Paystack
  bool verifyWebhookSignature(String payload, String signature) {
    try {
      final expectedSignature = _generateSignature(payload);
      final isValid = expectedSignature == signature;
      
      _logger.i('🔐 Webhook signature verification: ${isValid ? 'VALID' : 'INVALID'}');
      return isValid;
    } catch (e) {
      _logger.e('❌ Webhook signature verification failed: $e');
      return false;
    }
  }

  /// Generate expected webhook signature
  String _generateSignature(String payload) {
    final key = utf8.encode(_webhookSecret);
    final bytes = utf8.encode(payload);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return digest.toString();
  }

  /// Process incoming webhook event
  Future<bool> processWebhookEvent(
    String payload, 
    String signature,
  ) async {
    _logger.i('📨 Processing webhook event');

    try {
      // Verify webhook signature
      if (!verifyWebhookSignature(payload, signature)) {
        _logger.w('⚠️ Invalid webhook signature, ignoring event');
        return false;
      }

      // Parse webhook data
      final eventData = jsonDecode(payload);
      final webhookEvent = PaystackWebhookEvent.fromJson(eventData);

      _logger.i('📨 Webhook event type: ${webhookEvent.event}');

      // Handle different event types
      switch (webhookEvent.event) {
        case 'payment.success':
          return await _handlePaymentSuccess(webhookEvent);
        case 'payment.failed':
          return await _handlePaymentFailed(webhookEvent);
        case 'subscription.create':
          return await _handleSubscriptionCreate(webhookEvent);
        case 'subscription.disable':
          return await _handleSubscriptionDisable(webhookEvent);
        default:
          _logger.i('ℹ️ Unhandled webhook event: ${webhookEvent.event}');
          return true; // Don't fail for unknown events
      }
    } catch (e) {
      _logger.e('❌ Webhook processing failed: $e');
      return false;
    }
  }

  /// Handle payment.success webhook event
  Future<bool> _handlePaymentSuccess(PaystackWebhookEvent event) async {
    _logger.i('💳 Processing payment.success webhook');

    try {
      final paymentData = event.data;
      final reference = paymentData['reference'];
      final amount = paymentData['amount'];
      final paidAt = DateTime.tryParse(paymentData['paid_at'] ?? '') ?? DateTime.now();
      final metadata = paymentData['metadata'] ?? {};
      
      final userId = metadata['user_id'];
      final userEmail = metadata['user_email'];

      if (userId == null || userEmail == null) {
        _logger.w('⚠️ Missing user information in payment metadata');
        return false;
      }

      _logger.i('💰 Payment successful: ₦${amount / 100} for user $userEmail');

      // Calculate subscription end date (payment time + 7 days)
      final paidUntil = paidAt.add(const Duration(days: 7));

      // Update user subscription status
      final success = await _updateUserSubscription(
        userId: userId,
        paidAt: paidAt,
        paymentReference: reference,
        amountPaid: amount,
      );

      if (success) {
        _logger.i('✅ User subscription updated successfully');
        
        // Send confirmation notification (if needed)
        await _sendSubscriptionConfirmation(userEmail, paidUntil);
        
        return true;
      } else {
        _logger.e('❌ Failed to update user subscription');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Payment success handling failed: $e');
      return false;
    }
  }

  /// Handle payment.failed webhook event
  Future<bool> _handlePaymentFailed(PaystackWebhookEvent event) async {
    _logger.i('💳 Processing payment.failed webhook');

    try {
      final paymentData = event.data;
      final reference = paymentData['reference'];
      final metadata = paymentData['metadata'] ?? {};
      
      final userId = metadata['user_id'];
      final userEmail = metadata['user_email'];

      _logger.w('❌ Payment failed for reference: $reference');

      // Log the failed payment for tracking
      await _logFailedPayment(
        userId: userId,
        userEmail: userEmail,
        reference: reference,
        reason: paymentData['gateway_response'] ?? 'Unknown',
      );

      return true;
    } catch (e) {
      _logger.e('❌ Payment failed handling error: $e');
      return false;
    }
  }

  /// Handle subscription.create webhook event
  Future<bool> _handleSubscriptionCreate(PaystackWebhookEvent event) async {
    _logger.i('📅 Processing subscription.create webhook');
    // Implementation for subscription creation
    return true;
  }

  /// Handle subscription.disable webhook event
  Future<bool> _handleSubscriptionDisable(PaystackWebhookEvent event) async {
    _logger.i('📅 Processing subscription.disable webhook');
    // Implementation for subscription cancellation
    return true;
  }

  /// Update user subscription status in storage and database
  Future<bool> _updateUserSubscription({
    required String userId,
    required DateTime paidAt,
    required String paymentReference,
    required int amountPaid,
  }) async {
    try {
      // Get current user data
      final userModel = await _storageService.getRegisteredUser();
      if (userModel == null || userModel.id != userId) {
        _logger.e('❌ User data not found in storage for ID: $userId');
        return false;
      }
      
      // Use the new Paystack subscription activation method
      // This follows the scenario: paidUntil = paymentTime + 7 days, status = 'paid'
      userModel.activatePaystackSubscription(
        paymentTime: paidAt,
        paymentReference: paymentReference,
        amountPaid: amountPaid,
      );
      
      // Save to local storage
      await _storageService.saveRegisteredUser(userModel.toJson());
      
      // Save to database
      try {
        await _databaseService.updateUser(userModel);
        _logger.i('✅ User updated in database');
      } catch (e) {
        _logger.w('⚠️ Database update failed, but local storage updated: $e');
        // Continue even if database update fails
      }

      _logger.i('✅ User subscription updated successfully');
      return true;
    } catch (e) {
      _logger.e('❌ User subscription update failed: $e');
      return false;
    }
  }

  /// Send subscription confirmation
  Future<void> _sendSubscriptionConfirmation(
    String userEmail, 
    DateTime paidUntil,
  ) async {
    try {
      // Here you would integrate with your notification service
      // For now, just log the confirmation
      _logger.i('📧 Subscription confirmation for $userEmail until ${_formatDate(paidUntil)}');
      
      // TODO: Implement email/SMS notification
      // await _notificationService.sendSubscriptionConfirmation(userEmail, paidUntil);
    } catch (e) {
      _logger.w('⚠️ Failed to send subscription confirmation: $e');
    }
  }

  /// Log failed payment for tracking
  Future<void> _logFailedPayment({
    String? userId,
    String? userEmail,
    String? reference,
    String? reason,
  }) async {
    try {
      _logger.w('💸 Failed payment logged: $userEmail - $reference - $reason');
      
      // TODO: Store failed payment logs in database or analytics service
      // await _analyticsService.logFailedPayment({
      //   'user_id': userId,
      //   'user_email': userEmail,
      //   'reference': reference,
      //   'reason': reason,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      _logger.e('❌ Failed to log payment failure: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Simulate webhook event for testing
  Future<bool> simulatePaymentSuccessWebhook({
    required String userId,
    required String userEmail,
    required String reference,
    int amount = 60000, // ₦600 in kobo
  }) async {
    _logger.i('🧪 Simulating payment.success webhook for testing');

    // Check if user exists first - if not, return false
    final existingUser = await _storageService.getRegisteredUser();
    if (existingUser == null || existingUser.id != userId) {
      _logger.w('⚠️ User not found for webhook simulation: $userId');
      return false;
    }

    final webhookData = {
      'event': 'payment.success',
      'data': {
        'reference': reference,
        'amount': amount,
        'paid_at': DateTime.now().toIso8601String(),
        'status': 'success',
        'gateway_response': 'Successful',
        'metadata': {
          'user_id': userId,
          'user_email': userEmail,
          'subscription_type': 'weekly',
          'subscription_duration_days': 7,
        },
      },
    };

    final event = PaystackWebhookEvent.fromJson(webhookData);
    return await _handlePaymentSuccess(event);
  }
}