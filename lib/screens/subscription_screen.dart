import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/paystack_service.dart';
import '../services/webhook_service.dart';
import 'dashboard_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final UserModel userModel;

  const SubscriptionScreen({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final StorageService _storageService = StorageService();
  final PaystackService _paystackService = PaystackService();
  final WebhookService _webhookService = WebhookService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _logger.i('🔒 Subscription screen loaded for expired trial user');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildTrialExpiredCard(),
              const SizedBox(height: 32),
              _buildSubscriptionPlan(),
              const SizedBox(height: 32),
              _buildFeaturesList(),
              const SizedBox(height: 40),
              _buildSubscribeButton(),
              const SizedBox(height: 24),
              _buildAlternativeOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.lock_outlined,
            size: 40,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Trial Expired',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your 48-hour free trial has ended.\nSubscribe to continue accessing premium content.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTrialExpiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.orange.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Trial Period Complete',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userModel.trialDisplayMessage ?? 'Free trial ended',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlan() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Weekly Subscription',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '₦600',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '/week',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlimited access to all premium features',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      '📚 Unlimited quiz access',
      '🎯 Personalized study plans',
      '📊 Detailed performance analytics',
      '💡 Expert explanations',
      '⏰ Progress tracking',
      '🏆 Achievement badges',
      '📱 Offline access',
      '🔄 Regular content updates',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you\'ll get:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : _handleSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF10B981).withOpacity(0.4),
        ),
        child: _isProcessingPayment
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Text(
                'Subscribe for ₦600/week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildAlternativeOptions() {
    return Column(
      children: [
        TextButton(
          onPressed: _handleExtendTrial,
          child: Text(
            'Extend trial for 24 hours (Demo)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Go back',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubscription() async {
    setState(() {
      _isProcessingPayment = true;
    });

    _logger.i('💳 Starting Paystack subscription payment for ₦600/week');

    try {
      // Check required user data
      final userEmail = widget.userModel.email;
      final userId = widget.userModel.id;
      final userName = widget.userModel.fullName;

      if (userEmail == null || userId == null) {
        throw Exception('User email and ID are required for payment');
      }

      // Step 1: Initialize payment with Paystack
      final paymentResult = await _paystackService.processSubscriptionPayment(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        callbackUrl: 'https://your-app.com/payment-callback', // Replace with actual callback URL
      );

      if (!paymentResult.success) {
        throw Exception(paymentResult.error ?? 'Payment initialization failed');
      }

      _logger.i('💳 Payment initialized: ${paymentResult.reference}');

      // Step 2: Launch Paystack checkout page
      await _launchPaystackCheckout(paymentResult.authorizationUrl);

      // Step 3: Wait for payment completion and simulate webhook
      // In a real app, this would be handled by your backend webhook endpoint
      await _waitForPaymentCompletion(paymentResult.reference);

    } catch (e) {
      _logger.e('❌ Subscription payment failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  /// Launch Paystack checkout page
  Future<void> _launchPaystackCheckout(String authorizationUrl) async {
    _logger.i('🌐 Launching Paystack checkout: $authorizationUrl');
    
    final uri = Uri.parse(authorizationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch payment page');
    }
  }

  /// Wait for payment completion (simulated webhook for demo)
  Future<void> _waitForPaymentCompletion(String reference) async {
    _logger.i('⏳ Waiting for payment completion: $reference');
    
    // Show dialog asking user to confirm payment completion
    final completed = await _showPaymentCompletionDialog();
    
    if (completed) {
      // Simulate successful payment webhook
      final webhookSuccess = await _webhookService.simulatePaymentSuccessWebhook(
        userId: widget.userModel.id!,
        userEmail: widget.userModel.email!,
        reference: reference,
      );
      
      if (webhookSuccess) {
        // Reload user data to get updated subscription status
        await _reloadUserData();
        
        _logger.i('✅ Subscription activated successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Subscription activated! Welcome back!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userModel: widget.userModel),
            ),
          );
        }
      } else {
        throw Exception('Failed to process payment confirmation');
      }
    } else {
      throw Exception('Payment was not completed');
    }
  }

  /// Show dialog to confirm payment completion
  Future<bool> _showPaymentCompletionDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Status'),
          content: const Text(
            'Have you completed the payment on the Paystack page?\n\n'
            'Note: In a production app, this would be handled automatically via webhooks.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Payment Completed'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Reload user data after payment
  Future<void> _reloadUserData() async {
    try {
      final userData = await _storageService.getRegisteredUser();
      if (userData != null) {
        // Update the current user model with new data
        final updatedUser = userData;
        
        // Copy updated subscription data to current model
        widget.userModel.subscriptionStatus = updatedUser.subscriptionStatus;
        widget.userModel.status = updatedUser.status;
        widget.userModel.paidUntil = updatedUser.paidUntil;
        widget.userModel.paymentReference = updatedUser.paymentReference;
        widget.userModel.amountPaid = updatedUser.amountPaid;
        widget.userModel.lastPaymentDate = updatedUser.lastPaymentDate;
        widget.userModel.subscriptionEndTime = updatedUser.subscriptionEndTime;
      }
    } catch (e) {
      _logger.w('⚠️ Failed to reload user data: $e');
    }
  }

  Future<void> _handleExtendTrial() async {
    _logger.i('🔄 Extending trial for demo purposes');

    // Extend trial by 24 hours for demo
    widget.userModel.setTrialStatus(DateTime.now());
    await _storageService.saveRegisteredUser(widget.userModel.toJson());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Trial extended for 24 hours!'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userModel: widget.userModel),
        ),
      );
    }
  }
}