import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({Key? key}) : super(key: key);

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DemoAuthService _authService = DemoAuthService();
  final Logger _logger = Logger();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }



  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      _logger.i('Attempting to send OTP to phone number');

      // Use Firebase Authentication Service to send real OTP
      final result = await _authService.sendOTP(phoneNumber);

      if (!mounted) return;

      if (result.isSuccess) {
        // Create user model with phone number and verification ID
        final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        final userModel = UserModel(
          phoneNumber: cleanPhoneNumber, 
          verificationId: result.verificationId,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP sent successfully! Check your SMS.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to OTP verification with Firebase verification ID
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              userModel: userModel,
              verificationId: result.verificationId!,
            ),
          ),
        );
      } else {
        // Handle different types of errors with appropriate user messages
        String errorMessage = 'Failed to send OTP. Please try again.';
        
        if (result.error != null) {
          switch (result.error!) {
            case PhoneAuthError.invalidPhoneNumber:
              errorMessage = 'Invalid phone number format. Please enter a valid number with country code.';
              break;
            case PhoneAuthError.tooManyRequests:
              errorMessage = result.message;
              break;
            case PhoneAuthError.networkError:
              errorMessage = 'Network error. Please check your internet connection.';
              break;
            case PhoneAuthError.operationNotAllowed:
              errorMessage = 'Phone authentication is temporarily unavailable. Please try again later.';
              break;
            default:
              errorMessage = result.message;
          }
        }

        _logger.w('OTP send failed: ${result.message}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: result.error == PhoneAuthError.networkError
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _sendOTP,
                  )
                : null,
          ),
        );
      }
    } catch (error, stackTrace) {
      _logger.e('Unexpected error during OTP send', error: error, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Phone Number'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Verify Your Phone',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Enter your phone number to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Demo Mode Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Text(
                      '🎭 DEMO MODE\nNo real SMS will be sent\nUse code: 123456',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade100,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Phone number input
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: '+1 234 567 8900',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!value.startsWith('+')) {
                          return 'Please include country code (e.g., +44)';
                        }
                        // Remove all non-digit chars except + for length check
                        final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                        if (cleaned.length < 11 || cleaned.length > 15) {
                          return 'Please enter a valid phone number (10-14 digits)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Send OTP Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 