import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/navigation_guard_service.dart';
import '../services/twilio_auth_service.dart';
import '../main.dart'; // Import to access global authService

class OTPVerificationScreen extends StatefulWidget {
  final UserModel userModel;
  final String? verificationId; // Made optional for Twilio

  const OTPVerificationScreen({
    super.key,
    required this.userModel,
    this.verificationId, // Made optional
  });

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
  final StorageService _storageService = StorageService();
  final NavigationGuardService _navigationGuard = NavigationGuardService();
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
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number is missing');
      }

      // Use Twilio Authentication Service to verify OTP
      final verifiedUser = await authService.verifyOTP(phoneNumber, _currentOTP);

      if (!mounted) return;

      if (verifiedUser != null) {
        // Update the user model with verified user data
        widget.userModel.id = verifiedUser.id;
        widget.userModel.otpCode = _currentOTP;
        widget.userModel.isVerified = true;
        widget.userModel.lastLoginDate = DateTime.now();
        
        // Activate trial when signup completes
        widget.userModel.setTrialStatus(DateTime.now());
        
        // Map registration data to dashboard-expected fields
        // Map studyFocus to examTypes for dashboard display
        widget.userModel.examTypes = List<String>.from(widget.userModel.studyFocus);
        // Map scienceSubjects to subjects for dashboard display
        widget.userModel.subjects = List<String>.from(widget.userModel.scienceSubjects);
        
        // Set legacy fields for backward compatibility
        if (widget.userModel.examTypes.isNotEmpty) {
          widget.userModel.examType = widget.userModel.examTypes.first;
        }
        if (widget.userModel.subjects.isNotEmpty) {
          widget.userModel.subject = widget.userModel.subjects.first;
        }
        
        // Save/update user data in storage
        await _storageService.updateUser(widget.userModel);
        
        _logger.i('OTP verified successfully for user: ${verifiedUser.id ?? 'unknown'}');
        _logger.i('Trial activated - expires: ${widget.userModel.trialExpires}');
        _logger.i('Exam types: ${widget.userModel.examTypes}');
        _logger.i('Subjects: ${widget.userModel.subjects}');

        // Navigate based on user access status (trial/subscription)
        if (mounted) {
          _navigationGuard.navigateBasedOnAccess(context, widget.userModel);
        }
      }
    } catch (error) {
      _logger.w('OTP verification failed: $error');
      
      if (!mounted) return;
      
      // Check if this is a demo mode error with valid codes
      String errorMessage = error.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('Demo codes:')) {
        // Extract and format the demo codes message
        errorMessage = 'Invalid code. Try: 123456, 000000, 111111, or 555555';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _logger.i('Attempting to resend OTP code');
      
      // Check if phoneNumber is not null
      final phoneNumber = widget.userModel.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number is missing');
      }
      
      await authService.sendOTP(phoneNumber);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      _logger.e('Failed to resend OTP', error: error);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to resend OTP: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
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
                const SizedBox(height: 12),
                
                // Show demo codes hint in development mode
                if (authService is DemoAuthService)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🎭 Demo Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade200,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use any of these codes: 123456, 000000, 111111, 555555',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade100,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
