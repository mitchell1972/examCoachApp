import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/payment_models.dart';

/// Service for handling Paystack payment integration
class PaystackService {
  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService({http.Client? httpClient}) => _instance.._httpClient = httpClient ?? http.Client();
  PaystackService._internal();

  final Logger _logger = Logger();
  late http.Client _httpClient;
  
  // Paystack API configuration
  static const String _baseUrl = 'https://api.paystack.co';
  static const String _publicKey = 'pk_test_your_public_key_here'; // Replace with actual key
  static const String _secretKey = 'sk_test_your_secret_key_here'; // Replace with actual key
  
  /// Initialize a payment transaction
  Future<PaymentInitialization> initializePayment({
    required String email,
    required int amount, // Amount in kobo (₦600 = 60000 kobo)
    required String reference,
    String? callbackUrl,
    Map<String, dynamic>? metadata,
  }) async {
    _logger.i('💳 Initializing Paystack payment: ₦${amount / 100} for $email');

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amount,
          'reference': reference,
          'callback_url': callbackUrl,
          'metadata': metadata ?? {},
          'currency': 'NGN',
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        _logger.i('✅ Payment initialization successful');
        return PaymentInitialization.fromJson(data['data']);
      } else {
        throw PaystackException(
          'Payment initialization failed: ${data['message']}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _logger.e('❌ Payment initialization failed: $e');
      rethrow;
    }
  }

  /// Verify a payment transaction
  Future<PaymentVerification> verifyPayment(String reference) async {
    _logger.i('🔍 Verifying payment with reference: $reference');

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        _logger.i('✅ Payment verification successful');
        return PaymentVerification.fromJson(data['data']);
      } else {
        throw PaystackException(
          'Payment verification failed: ${data['message']}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _logger.e('❌ Payment verification failed: $e');
      rethrow;
    }
  }

  /// Generate a unique payment reference
  String generatePaymentReference({String? userId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    final prefix = userId != null && userId.length >= 8 
        ? userId.substring(0, 8) 
        : userId ?? 'user';
    return 'exam_coach_${prefix}_${timestamp}_$random';
  }

  /// Get payment amount for weekly subscription (in kobo)
  int getWeeklySubscriptionAmount() {
    return 60000; // ₦600 in kobo
  }

  /// Create subscription payment metadata
  Map<String, dynamic> createSubscriptionMetadata({
    required String userId,
    required String userEmail,
    String? userName,
  }) {
    return {
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName ?? '',
      'subscription_type': 'weekly',
      'subscription_duration_days': 7,
      'product': 'exam_coach_premium',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Process subscription payment (complete flow)
  Future<SubscriptionPaymentResult> processSubscriptionPayment({
    required String userId,
    required String userEmail,
    String? userName,
    String? callbackUrl,
  }) async {
    _logger.i('🚀 Starting subscription payment process for user: $userEmail');

    try {
      // Generate payment reference
      final reference = generatePaymentReference(userId: userId);
      
      // Get payment amount
      final amount = getWeeklySubscriptionAmount();
      
      // Create metadata
      final metadata = createSubscriptionMetadata(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
      );

      // Initialize payment
      final initialization = await initializePayment(
        email: userEmail,
        amount: amount,
        reference: reference,
        callbackUrl: callbackUrl,
        metadata: metadata,
      );

      _logger.i('💳 Payment initialized with reference: $reference');

      return SubscriptionPaymentResult(
        reference: reference,
        authorizationUrl: initialization.authorizationUrl,
        accessCode: initialization.accessCode,
        amount: amount,
        success: true,
      );
    } catch (e) {
      _logger.e('❌ Subscription payment process failed: $e');
      return SubscriptionPaymentResult(
        reference: '',
        authorizationUrl: '',
        accessCode: '',
        amount: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle payment callback after successful payment
  Future<PaymentCallbackResult> handlePaymentCallback({
    required String reference,
    required String userId,
  }) async {
    _logger.i('🔄 Handling payment callback for reference: $reference');

    try {
      // Verify the payment
      final verification = await verifyPayment(reference);
      
      if (verification.status == 'success') {
        _logger.i('✅ Payment verified successfully');
        
        // Calculate subscription end date (7 days from payment time)
        final paymentTime = verification.paidAt ?? DateTime.now();
        final paidUntil = paymentTime.add(const Duration(days: 7));
        
        return PaymentCallbackResult(
          success: true,
          reference: reference,
          amount: verification.amount,
          paidAt: paymentTime,
          paidUntil: paidUntil,
          gatewayResponse: verification.gatewayResponse,
        );
      } else {
        _logger.w('⚠️ Payment verification failed: ${verification.status}');
        return PaymentCallbackResult(
          success: false,
          reference: reference,
          error: 'Payment verification failed: ${verification.status}',
        );
      }
    } catch (e) {
      _logger.e('❌ Payment callback handling failed: $e');
      return PaymentCallbackResult(
        success: false,
        reference: reference,
        error: e.toString(),
      );
    }
  }
}

/// Exception class for Paystack-related errors
class PaystackException implements Exception {
  final String message;
  final int? statusCode;
  
  PaystackException(this.message, {this.statusCode});
  
  @override
  String toString() => 'PaystackException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}