import 'package:flutter/material.dart';
import 'phone_input_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // App Logo/Icon
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                
                // App Title
                const Text(
                  'Exam Coach',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'Get personalized quizzes for your exam preparation',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                                // Sign Up Button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to phone input screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PhoneInputScreen(),
                      ),
                    );
                  },
                                     style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.deepPurple,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                                     child: const Text(
                     'Sign Up',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                                 ),
                 const SizedBox(height: 16),
                
                // Login Button
                OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to login screen
                                         ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Login pressed!')),
                     );
                  },
                                     style: OutlinedButton.styleFrom(
                     foregroundColor: Colors.white,
                     side: const BorderSide(color: Colors.white, width: 2),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                                     child: const Text(
                     'Login',
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
    );
  }
} 