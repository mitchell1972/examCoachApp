import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/twilio_auth_service.dart';
import '../main.dart';
import 'otp_verification_screen.dart';
import 'forgot_phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _logger = Logger();
  final _storageService = StorageService();
  
  UserModel? _registeredUser;
  bool _isLoading = false;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredUser();
  }

  Future<void> _loadRegisteredUser() async {
    try {
      final user = await _storageService.getRegisteredUser();
      setState(() {
        _registeredUser = user;
        _isLoadingUser = false;
      });
      
      if (user != null) {
        _logger.i('✅ Found registered user: ${user.phoneNumber}');
      } else {
        _logger.w('⚠️ No registered user found');
      }
    } catch (e) {
      _logger.e('❌ Failed to load registered user: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (_registeredUser?.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number found. Please register first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.sendOTP(_registeredUser!.phoneNumber!);
      
      _logger.i('✅ OTP sent successfully to ${_registeredUser!.phoneNumber}');
      
      if (mounted) {
        // Update last login attempt
        _registeredUser!.lastLoginDate = DateTime.now();
        await _storageService.updateUser(_registeredUser!);
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              userModel: _registeredUser!,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Failed to send OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: Colors.red,
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

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 8) return phoneNumber;
    final start = phoneNumber.substring(0, phoneNumber.length - 8);
    final end = phoneNumber.substring(phoneNumber.length - 4);
    return '$start****$end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
          child: _isLoadingUser
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _registeredUser == null
                  ? _buildNoUserFound()
                  : _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildNoUserFound() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // No User Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          const Text(
            'No Account Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Message
          Text(
            'You need to create an account first before you can login.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Register Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Back
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Hello ${_registeredUser!.fullName ?? 'Student'}, ready to continue learning?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // User Info Card
          _buildUserInfoCard(),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sms, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Send OTP to ${_maskPhoneNumber(_registeredUser!.phoneNumber!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          
          // Forgot Phone Button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgotPhoneScreen(),
                ),
              );
            },
            child: Text(
              'Forgot phone number?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Use Different Number
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Use Different Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _registeredUser!.fullName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _registeredUser!.phoneNumber ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_registeredUser!.currentClass != null || 
              _registeredUser!.studyFocus.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            if (_registeredUser!.currentClass != null)
              _buildInfoRow('Class', _registeredUser!.currentClass!),
            
            if (_registeredUser!.studyFocus.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Study Focus:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _registeredUser!.studyFocus.take(3).map((focus) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      focus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_registeredUser!.studyFocus.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${_registeredUser!.studyFocus.length - 3} more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
