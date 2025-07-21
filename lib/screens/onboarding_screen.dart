import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../services/app_config.dart';
import '../services/error_handler.dart';

/// Secure and accessible onboarding screen with Sign Up and Login options
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> 
    with TickerProviderStateMixin {
  static final Logger _logger = Logger();
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = false;
  bool _buttonsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _logScreenView();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Initialize animations for smooth UI transitions
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  /// Log screen view for analytics (respecting user privacy settings)
  void _logScreenView() {
    try {
      if (AppConfig.instance.isAnalyticsEnabled) {
        _logger.i('Onboarding screen viewed');
      }
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error, 
        stackTrace, 
        context: 'OnboardingScreen._logScreenView',
        severity: ErrorSeverity.warning,
      );
    }
  }

  /// Handle Sign Up button press with security and error handling
  Future<void> _handleSignUpPressed() async {
    await _handleButtonPress('SignUp', () async {
      _logger.d('Sign Up button pressed');
      
      // Add haptic feedback for better UX
      await HapticFeedback.lightImpact();
      
      // Validate security context
      if (!await _validateSecurityContext()) {
        return;
      }
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sign Up pressed - Navigation will be implemented'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // TODO: Navigate to sign up screen
      // Navigator.of(context).pushNamed('/signup');
    });
  }

  /// Handle Login button press with security and error handling
  Future<void> _handleLoginPressed() async {
    await _handleButtonPress('Login', () async {
      _logger.d('Login button pressed');
      
      // Add haptic feedback for better UX
      await HapticFeedback.lightImpact();
      
      // Validate security context
      if (!await _validateSecurityContext()) {
        return;
      }
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Login pressed - Navigation will be implemented'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // TODO: Navigate to login screen
      // Navigator.of(context).pushNamed('/login');
    });
  }

  /// Generic button press handler with loading state and error handling
  Future<void> _handleButtonPress(String buttonName, Future<void> Function() action) async {
    if (!_buttonsEnabled || _isLoading) return;
    
    try {
      setState(() {
        _isLoading = true;
        _buttonsEnabled = false;
      });
      
      await action();
      
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error, 
        stackTrace, 
        context: 'OnboardingScreen._handleButtonPress($buttonName)',
        additionalData: {'button': buttonName},
        severity: ErrorSeverity.error,
      );
      
      if (mounted) {
        final errorInfo = ErrorHandler.handleException(error);
        ErrorHandler.showErrorDialog(context, errorInfo);
      }
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _buttonsEnabled = true;
        });
      }
    }
  }

  /// Validate security context before sensitive operations
  Future<bool> _validateSecurityContext() async {
    try {
      // Basic security checks could be added here
      // For example, checking if the app is running in a secure environment
      
      return true; // Placeholder - implement actual security validation
      
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error, 
        stackTrace, 
        context: 'OnboardingScreen._validateSecurityContext',
        severity: ErrorSeverity.warning,
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Title Section
                  _buildLogoSection(colorScheme),
                  
                  const SizedBox(height: 48),
                  
                  // Action Buttons Section
                  _buildActionButtons(colorScheme),
                  
                  const SizedBox(height: 32),
                  
                  // Terms and Privacy Section
                  _buildTermsSection(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the logo and title section
  Widget _buildLogoSection(ColorScheme colorScheme) {
    return Column(
      children: [
        // App Logo with semantic label for accessibility
        Semantics(
          label: 'Exam Coach App Logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App Title
        Text(
          AppConfig.instance.appDisplayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          semanticsLabel: 'App title: ${AppConfig.instance.appDisplayName}',
        ),
        
        const SizedBox(height: 8),
        
        // App Description
        Text(
          'Get personalized quizzes for your exam preparation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Build the action buttons section
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sign Up Button
        _buildButton(
          key: const Key('signUpButton'),
          text: 'Sign Up',
          onPressed: _buttonsEnabled ? _handleSignUpPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          semanticsLabel: 'Sign up to create a new account',
        ),
        
        const SizedBox(height: 16),
        
        // Login Button
        _buildButton(
          key: const Key('loginButton'),
          text: 'Login',
          onPressed: _buttonsEnabled ? _handleLoginPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          semanticsLabel: 'Login to your existing account',
          isOutlined: true,
        ),
      ],
    );
  }

  /// Build a styled button with accessibility and loading state
  Widget _buildButton({
    required Key key,
    required String text,
    required VoidCallback? onPressed,
    required ButtonStyle style,
    required String semanticsLabel,
    bool isOutlined = false,
  }) {
    Widget button = isOutlined 
        ? OutlinedButton(
            key: key,
            onPressed: onPressed,
            style: style,
            child: _buildButtonContent(text),
          )
        : ElevatedButton(
            key: key,
            onPressed: onPressed,
            style: style,
            child: _buildButtonContent(text),
          );
    
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      hint: onPressed == null ? 'Button is disabled' : 'Double tap to activate',
      child: button,
    );
  }

  /// Build button content with loading indicator
  Widget _buildButtonContent(String text) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build terms and privacy section
  Widget _buildTermsSection(ThemeData theme) {
    return Semantics(
      label: 'Terms and privacy information',
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 