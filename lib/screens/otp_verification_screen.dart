import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../main.dart'; // Import to access global authService
import 'exam_selection_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final UserModel userModel;
  final String? verificationId; // Made optional for Twilio

  const OTPVerificationScreen({
    Key? key,
    required this.userModel,
    this.verificationId, // Made optional
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final Logger _logger = Logger();
  bool _isLoading = false;
  String _currentOTP = '';

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOTPChanged(String value, int index) {
    setState(() {
      _currentOTP = _otpControllers.map((c) => c.text).join();
    });

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_currentOTP.length == 6) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (_currentOTP.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.i('Attempting to verify OTP code');

      // Check if phoneNumber is not null
      final phoneNumber = widget.userModel.phoneNumber;
      if (phoneNumber == null) {
        throw Exception('Phone number is missing');
      }

      // Use Twilio Authentication Service to verify OTP
      final verifiedUser = await authService.verifyOTP(phoneNumber, _currentOTP);

      if (!mounted) return;

      if (verifiedUser != null) {
        // Update the user model with verified user data
        widget.userModel.id = verifiedUser.id;
        widget.userModel.otpCode = _currentOTP;
        
        _logger.i('OTP verified successfully for user: ${verifiedUser.id}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Phone number verified successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to exam selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ExamSelectionScreen(userModel: widget.userModel),
          ),
        );
      } else {
        // Handle verification failure
        _logger.w('OTP verification failed: Invalid verification code');

        // Clear OTP fields on error
        _clearOTPFields();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid verification code. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );

        // Focus on first OTP field for retry
        _focusNodes[0].requestFocus();
      }
    } catch (error, stackTrace) {
      _logger.e('Unexpected error during OTP verification', error: error, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );

        // Clear OTP fields and focus first field
        _clearOTPFields();
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    try {
      _logger.i('Attempting to resend OTP');

      // Check if phoneNumber is not null
      final phoneNumber = widget.userModel.phoneNumber;
      if (phoneNumber == null) {
        throw Exception('Phone number is missing');
      }

      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Resending OTP...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Use Twilio Authentication Service to resend OTP
      await authService.sendOTP(phoneNumber);

      if (!mounted) return;

      // Clear current OTP fields
      _clearOTPFields();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ OTP resent successfully! Check your SMS.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Focus on first OTP field
      _focusNodes[0].requestFocus();
    } catch (error, stackTrace) {
      _logger.e('Error during OTP resend', error: error, stackTrace: stackTrace);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to resend OTP. Please try again later.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Clear all OTP input fields
  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _currentOTP = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.message,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Enter the 6-digit code sent to ${widget.userModel.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Environment Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kReleaseMode 
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kReleaseMode 
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    kReleaseMode 
                      ? '📱 OTP sending may fail\n⚠️ Firebase config incomplete'
                      : '🎭 DEMO CODE: 123456\n(No real SMS sent)',
                    style: TextStyle(
                      fontSize: 16,
                      color: kReleaseMode 
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // OTP Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focusNodes[index].hasFocus
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        onChanged: (value) => _onOTPChanged(value, index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                
                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Resend OTP Button
                TextButton(
                  onPressed: _resendOTP,
                  child: Text(
                    'Didn\'t receive code? Resend',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 