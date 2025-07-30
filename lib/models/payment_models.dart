// Models for payment and subscription management

/// Payment initialization response from Paystack
class PaymentInitialization {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaymentInitialization({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory PaymentInitialization.fromJson(Map<String, dynamic> json) {
    return PaymentInitialization(
      authorizationUrl: json['authorization_url'] ?? '',
      accessCode: json['access_code'] ?? '',
      reference: json['reference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_url': authorizationUrl,
      'access_code': accessCode,
      'reference': reference,
    };
  }
}

/// Payment verification response from Paystack
class PaymentVerification {
  final String id;
  final String reference;
  final int amount;
  final String status;
  final String gatewayResponse;
  final DateTime? paidAt;
  final String channel;
  final String currency;
  final Map<String, dynamic>? metadata;

  PaymentVerification({
    required this.id,
    required this.reference,
    required this.amount,
    required this.status,
    required this.gatewayResponse,
    this.paidAt,
    required this.channel,
    required this.currency,
    this.metadata,
  });

  factory PaymentVerification.fromJson(Map<String, dynamic> json) {
    return PaymentVerification(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      gatewayResponse: json['gateway_response'] ?? '',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      channel: json['channel'] ?? '',
      currency: json['currency'] ?? 'NGN',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'amount': amount,
      'status': status,
      'gateway_response': gatewayResponse,
      'paid_at': paidAt?.toIso8601String(),
      'channel': channel,
      'currency': currency,
      'metadata': metadata,
    };
  }

  bool get isSuccessful => status == 'success';
}

/// Result of subscription payment processing
class SubscriptionPaymentResult {
  final String reference;
  final String authorizationUrl;
  final String accessCode;
  final int amount;
  final bool success;
  final String? error;

  SubscriptionPaymentResult({
    required this.reference,
    required this.authorizationUrl,
    required this.accessCode,
    required this.amount,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'authorization_url': authorizationUrl,
      'access_code': accessCode,
      'amount': amount,
      'success': success,
      'error': error,
    };
  }
}

/// Result of payment callback handling
class PaymentCallbackResult {
  final bool success;
  final String reference;
  final int? amount;
  final DateTime? paidAt;
  final DateTime? paidUntil;
  final String? gatewayResponse;
  final String? error;

  PaymentCallbackResult({
    required this.success,
    required this.reference,
    this.amount,
    this.paidAt,
    this.paidUntil,
    this.gatewayResponse,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'reference': reference,
      'amount': amount,
      'paid_at': paidAt?.toIso8601String(),
      'paid_until': paidUntil?.toIso8601String(),
      'gateway_response': gatewayResponse,
      'error': error,
    };
  }
}

/// Webhook event data from Paystack
class PaystackWebhookEvent {
  final String event;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  PaystackWebhookEvent({
    required this.event,
    required this.data,
    this.createdAt,
  });

  factory PaystackWebhookEvent.fromJson(Map<String, dynamic> json) {
    return PaystackWebhookEvent(
      event: json['event'] ?? '',
      data: json['data'] ?? {},
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'data': data,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isPaymentSuccess => event == 'payment.success';
}

/// Subscription status data
class SubscriptionStatus {
  final String userId;
  final String status; // 'active', 'expired', 'cancelled'
  final DateTime? paidAt;
  final DateTime? paidUntil;
  final String? paymentReference;
  final int? amountPaid;
  final String subscriptionType;

  SubscriptionStatus({
    required this.userId,
    required this.status,
    this.paidAt,
    this.paidUntil,
    this.paymentReference,
    this.amountPaid,
    this.subscriptionType = 'weekly',
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      userId: json['user_id'] ?? '',
      status: json['status'] ?? 'none',
      paidAt: json['paid_at'] != null 
          ? DateTime.tryParse(json['paid_at']) 
          : null,
      paidUntil: json['paid_until'] != null 
          ? DateTime.tryParse(json['paid_until']) 
          : null,
      paymentReference: json['payment_reference'],
      amountPaid: json['amount_paid'],
      subscriptionType: json['subscription_type'] ?? 'weekly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'paid_until': paidUntil?.toIso8601String(),
      'payment_reference': paymentReference,
      'amount_paid': amountPaid,
      'subscription_type': subscriptionType,
    };
  }

  bool get isActive => status == 'active' && 
                      paidUntil != null && 
                      DateTime.now().isBefore(paidUntil!);

  bool get isExpired => paidUntil != null && 
                       DateTime.now().isAfter(paidUntil!);

  String get displayMessage {
    if (isActive && paidUntil != null) {
      final daysRemaining = paidUntil!.difference(DateTime.now()).inDays;
      return 'Subscription active until ${_formatDate(paidUntil!)} ($daysRemaining days remaining)';
    } else if (isExpired) {
      return 'Subscription expired on ${paidUntil != null ? _formatDate(paidUntil!) : 'Unknown date'}';
    } else {
      return 'No active subscription';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}