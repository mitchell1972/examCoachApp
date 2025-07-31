import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import 'registration_success_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _logger = Logger();
  final _storageService = StorageService();
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form data
  String? _currentClass;
  String? _schoolType;
  List<String> _studyFocus = [];
  List<String> _scienceSubjects = [];
  DateTime? _targetExamDate;
  int? _studyHoursPerWeek;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  // Available options
  final List<String> _classOptions = [
    'SS1', 'SS2', 'SS3', 'Graduate', 'Other'
  ];
  
  final List<String> _schoolTypeOptions = [
    'Public School', 'Private School', 'Homeschool', 'Not in school'
  ];
  
  final List<Map<String, dynamic>> _studyFocusOptions = [
    {'value': 'JAMB', 'label': 'JAMB Preparation', 'icon': Icons.school},
    {'value': 'WAEC', 'label': 'WAEC Preparation', 'icon': Icons.assignment},
    {'value': 'NECO', 'label': 'NECO Preparation', 'icon': Icons.quiz},
    {'value': 'Subject Mastery', 'label': 'Subject Mastery', 'icon': Icons.psychology},
    {'value': 'General Review', 'label': 'General Review', 'icon': Icons.refresh},
  ];
  
  final List<Map<String, dynamic>> _scienceSubjectOptions = [
    {'value': 'Mathematics', 'label': 'Mathematics', 'icon': Icons.calculate},
    {'value': 'Physics', 'label': 'Physics', 'icon': Icons.science},
    {'value': 'Chemistry', 'label': 'Chemistry', 'icon': Icons.biotech},
    {'value': 'Biology', 'label': 'Biology', 'icon': Icons.eco},
    {'value': 'Further Mathematics', 'label': 'Further Mathematics', 'icon': Icons.functions},
    {'value': 'Agricultural Science', 'label': 'Agricultural Science', 'icon': Icons.agriculture},
    {'value': 'Geography', 'label': 'Geography', 'icon': Icons.public},
    {'value': 'Computer Science', 'label': 'Computer Science/ICT', 'icon': Icons.computer},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Debug helper method
  void _debugPhoneState(String context) {
    _logger.i('🔍 [$context] Phone controller text: "${_phoneController.text}"');
    _logger.i('🔍 [$context] Phone controller length: ${_phoneController.text.length}');
    _logger.i('🔍 [$context] Phone controller isEmpty: ${_phoneController.text.isEmpty}');
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validate current step before proceeding
      _logger.i('🔍 Validating step $_currentStep before navigation...');
      
      if (!_validateCurrentStep()) {
        _logger.w('⚠️ Step $_currentStep validation failed, preventing navigation');
        return;
      }
      
      // Debug: Check form state before moving to next step
      _logger.i('🔍 Moving from step $_currentStep to ${_currentStep + 1}');
      _debugPhoneState('NEXT_STEP');
      _logger.i('🔍 Full name: "${_fullNameController.text}"');
      _logger.i('🔍 Email: "${_emailController.text}"');
      
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeRegistration() async {
    // Debug: Check phone state at the very beginning
    _debugPhoneState('REGISTRATION_START');
    
    // Check if form validation affects phone controller
    _logger.i('🔍 About to validate form...');
    final formIsValid = _formKey.currentState!.validate();
    _debugPhoneState('AFTER_FORM_VALIDATE');
    
    if (!formIsValid || !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields and accept terms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _debugPhoneState('BEFORE_SET_LOADING');
    setState(() {
      _isLoading = true;
    });
    _debugPhoneState('AFTER_SET_LOADING');

    try {
      // Run async validations for phone and email before proceeding
      _logger.i('🔍 Running duplicate user validation...');
      
      // Debug: Check controller state before validation
      _debugPhoneState('BEFORE_ASYNC_VALIDATION');
      
      // CRITICAL: Run validations SEQUENTIALLY to prevent race conditions
      // The issue was that phone and email validations were running simultaneously
      // and both calling checkForDuplicateUser, causing interference
      
      _logger.i('🔍 Step 1: Validating phone number...');
      final phoneValidation = await _validatePhoneAsync(_phoneController.text.trim());
      if (phoneValidation != null) {
        _logger.e('❌ Phone validation failed: $phoneValidation');
        throw Exception(phoneValidation);
      }
      _logger.i('✅ Phone validation passed');
      
      _logger.i('🔍 Step 2: Validating email address...');
      final emailValidation = await _validateEmailAsync(_emailController.text.trim());
      if (emailValidation != null) {
        _logger.e('❌ Email validation failed: $emailValidation');
        throw Exception(emailValidation);
      }
      _logger.i('✅ Email validation passed');
      
      _logger.i('✅ Duplicate validation passed, proceeding with registration...');
      final user = UserModel(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        currentClass: _currentClass,
        schoolType: _schoolType,
        studyFocus: _studyFocus,
        scienceSubjects: _scienceSubjects,
        targetExamDate: _targetExamDate,
        studyHoursPerWeek: _studyHoursPerWeek,
        isRegistered: true,
        registrationDate: DateTime.now(),
        registrationStatus: 'completed',
        status: 'registered',
      );
      
      // Set the password securely
      user.setPassword(_passwordController.text);

      await _storageService.saveRegistration(user);
      
      _logger.i('✅ Registration completed successfully');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RegistrationSuccessScreen(user: user),
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Registration failed: $e');
      if (mounted) {
        // Clean up error message by removing "Exception: " prefix
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Give users time to read the message
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

  String? _validatePhone(String? value) {
    // Debug: Log phone validation
    _logger.i('🔍 _validatePhone called with: "${value ?? "null"}"');
    
    // Don't show validation error immediately when field is empty
    // Only validate when user has actually interacted with the field
    if (value == null || value.trim().isEmpty) {
      _logger.i('🔍 Phone validation: empty value, returning null');
      return null; // Don't show error immediately
    }
    
    // Remove spaces and special characters (keep only digits and +)
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    _logger.i('🔍 Phone validation: cleaned value: "$cleanPhone"');
    
    // Check if it starts with country code
    if (!cleanPhone.startsWith('+')) {
      return 'Phone number must include country code (e.g., +234)';
    }
    
    // Check length (country code + 10-11 digits)
    if (cleanPhone.length < 13 || cleanPhone.length > 15) {
      return 'Invalid phone number length';
    }
    
    _logger.i('🔍 Phone validation: passed all checks');
    return null;
  }

  /// Validate phone number and check for duplicates (async validation)
  Future<String?> _validatePhoneAsync(String? value) async {
    // During registration, phone number IS required
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Do format validation
    final basicValidation = _validatePhone(value);
    if (basicValidation != null) {
      return basicValidation;
    }
    
    // If basic validation passes, check for duplicates
    try {
      final duplicateError = await _storageService.checkForDuplicateUser(
        phoneNumber: value.trim(),
        email: null,
      );
      return duplicateError;
    } catch (e) {
      // Don't fail validation if we can't check duplicates
      _logger.w('Could not check for duplicate phone number: $e');
      return null;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for numbers
    if (RegExp(r'\d').hasMatch(value)) {
      return 'Name cannot contain numbers';
    }
    
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate email format only (no duplicate check to avoid phone interference)
  Future<String?> _validateEmailAsync(String? value) async {
    // Email is optional, so empty value is OK
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    // Only do basic validation - no duplicate checking
    // This prevents interference with phone number validation
    final basicValidation = _validateEmail(value);
    if (basicValidation != null) {
      return basicValidation;
    }
    
    // Email validation passed - no duplicate check needed since:
    // 1. Email is optional in the app
    // 2. Phone number is the primary identifier
    // 3. Prevents race conditions with phone validation
    _logger.i('✅ Email format validation passed');
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate the current step before allowing navigation
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Information step
        return _validateBasicInformationStep();
      case 1: // Academic Profile step
        return _validateAcademicProfileStep();
      case 2: // Subject Selection step
        return _validateSubjectSelectionStep();
      case 3: // Study Goals step
        return _validateStudyGoalsStep();
      default:
        return true;
    }
  }

  /// Validate Step 0: Basic Information (Name, Phone, Email, Password, Confirm Password)
  bool _validateBasicInformationStep() {
    _logger.i('🔍 Validating basic information step...');
    
    // Validate full name
    final nameError = _validateName(_fullNameController.text);
    if (nameError != null) {
      _logger.w('❌ Name validation failed: $nameError');
      _showValidationError('Full Name Error', nameError);
      return false;
    }
    
    // Validate phone number
    final phoneError = _validatePhone(_phoneController.text);
    if (phoneError != null) {
      _logger.w('❌ Phone validation failed: $phoneError');
      _showValidationError('Phone Number Error', phoneError);
      return false;
    }
    
    // Validate email
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _logger.w('❌ Email validation failed: $emailError');
      _showValidationError('Email Error', emailError);
      return false;
    }
    
    // Validate password
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _logger.w('❌ Password validation failed: $passwordError');
      _showValidationError('Password Error', passwordError);
      return false;
    }
    
    // Validate password confirmation - CRITICAL for password matching
    final confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
    if (confirmPasswordError != null) {
      _logger.w('❌ Password confirmation failed: $confirmPasswordError');
      _showValidationError('Password Confirmation Error', confirmPasswordError);
      return false;
    }
    
    _logger.i('✅ Basic information validation passed');
    return true;
  }

  /// Validate Step 1: Academic Profile (Class, School Type, Study Focus)
  bool _validateAcademicProfileStep() {
    _logger.i('🔍 Validating academic profile step...');
    
    if (_currentClass == null || _currentClass!.isEmpty) {
      _showValidationError('Academic Profile Error', 'Please select your current class');
      return false;
    }
    
    if (_schoolType == null || _schoolType!.isEmpty) {
      _showValidationError('Academic Profile Error', 'Please select your school type');
      return false;
    }
    
    if (_studyFocus.isEmpty) {
      _showValidationError('Academic Profile Error', 'Please select at least one study focus');
      return false;
    }
    
    _logger.i('✅ Academic profile validation passed');
    return true;
  }

  /// Validate Step 2: Subject Selection (Science Subjects)
  bool _validateSubjectSelectionStep() {
    _logger.i('🔍 Validating subject selection step...');
    
    if (_scienceSubjects.isEmpty) {
      _showValidationError('Subject Selection Error', 'Please select at least one science subject you want to study');
      return false;
    }
    
    _logger.i('✅ Subject selection validation passed');
    return true;
  }

  /// Validate Step 3: Study Goals (Target Exam Date, Study Hours)
  bool _validateStudyGoalsStep() {
    _logger.i('🔍 Validating study goals step...');
    
    if (_targetExamDate == null) {
      _showValidationError('Study Goals Error', 'Please select your target exam date');
      return false;
    }
    
    if (_studyHoursPerWeek == null || _studyHoursPerWeek! <= 0) {
      _showValidationError('Study Goals Error', 'Please select how many hours per week you plan to study');
      return false;
    }
    
    _logger.i('✅ Study goals validation passed');
    return true;
  }

  /// Show validation error message to user
  void _showValidationError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBasicInfoStep(),
                      _buildAcademicProfileStep(),
                      _buildSubjectSelectionStep(),
                      _buildStudyGoalsStep(),
                    ],
                  ),
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with your basic details',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: _validateName,
            required: true,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            hint: '+234 801 234 5678',
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            required: true,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            hint: 'your.email@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            required: true,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            hint: 'Enter a secure password',
            obscureText: true,
            validator: _validatePassword,
            required: true,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            hint: 'Confirm your password',
            obscureText: true,
            validator: _validateConfirmPassword,
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your current academic level',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildDropdownField(
            label: 'Current Class',
            value: _currentClass,
            items: _classOptions,
            onChanged: (value) => setState(() => _currentClass = value),
            required: true,
          ),
          const SizedBox(height: 20),
          
          _buildDropdownField(
            label: 'School Type',
            value: _schoolType,
            items: _schoolTypeOptions,
            onChanged: (value) => setState(() => _schoolType = value),
            required: true,
          ),
          const SizedBox(height: 32),
          
          _buildMultiSelectSection(
            title: 'Study Focus',
            subtitle: 'What are you preparing for? (Select all that apply)',
            options: _studyFocusOptions,
            selectedValues: _studyFocus,
            onChanged: (values) => setState(() => _studyFocus = values),
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Science Subjects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Which science subjects are you interested in?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildMultiSelectSection(
            title: 'Select Subjects',
            subtitle: 'Choose all subjects you want to study',
            options: _scienceSubjectOptions,
            selectedValues: _scienceSubjects,
            onChanged: (values) => setState(() => _scienceSubjects = values),
            required: true,
            showSelectAll: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGoalsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Goals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your learning experience',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildDateField(
            label: 'Target Exam Date (Optional)',
            value: _targetExamDate,
            onChanged: (date) => setState(() => _targetExamDate = date),
          ),
          const SizedBox(height: 20),
          
          _buildNumberField(
            label: 'Study Hours Per Week (Optional)',
            value: _studyHoursPerWeek,
            onChanged: (hours) => setState(() => _studyHoursPerWeek = hours),
            min: 1,
            max: 50,
          ),
          const SizedBox(height: 32),
          
          _buildTermsCheckbox(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool required = false,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: required ? (value) => value == null ? 'This field is required' : null : null,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Colors.deepPurple.shade600,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required List<String> selectedValues,
    required void Function(List<String>) onChanged,
    bool required = false,
    bool showSelectAll = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$title *' : title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        
        if (showSelectAll)
          _buildSelectAllButton(options, selectedValues, onChanged),
        
        ...options.map((option) {
          final isSelected = selectedValues.contains(option['value']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final newValues = List<String>.from(selectedValues);
                  if (isSelected) {
                    newValues.remove(option['value']);
                  } else {
                    newValues.add(option['value']);
                  }
                  onChanged(newValues);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        
        if (required && selectedValues.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one option',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectAllButton(
    List<Map<String, dynamic>> options,
    List<String> selectedValues,
    void Function(List<String>) onChanged,
  ) {
    final allSelected = options.every((option) => selectedValues.contains(option['value']));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (allSelected) {
              onChanged([]);
            } else {
              onChanged([...options.map((option) => option['value'] as String)]);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allSelected ? Icons.deselect : Icons.select_all,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            onChanged(date);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value != null
                          ? '${value.day}/${value.month}/${value.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: value != null ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int? value,
    required void Function(int?) onChanged,
    int min = 1,
    int max = 100,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: value != null && value > min
                    ? () => onChanged(value - 1)
                    : null,
                icon: const Icon(Icons.remove),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Expanded(
                child: Text(
                  value?.toString() ?? 'Not set',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: value != null ? Colors.white : Colors.white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: (value ?? 0) < max
                    ? () => onChanged((value ?? 0) + 1)
                    : null,
                icon: const Icon(Icons.add),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          activeColor: Colors.white,
          checkColor: Colors.deepPurple,
          side: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_currentStep == _totalSteps - 1) {
                  _completeRegistration();
                } else {
                  // Validate current step
                  bool canProceed = true;
                  
                  if (_currentStep == 0) {
                    canProceed = _fullNameController.text.trim().isNotEmpty &&
                                _phoneController.text.trim().isNotEmpty &&
                                _validatePhone(_phoneController.text) == null &&
                                _validateName(_fullNameController.text) == null;
                  } else if (_currentStep == 1) {
                    canProceed = _currentClass != null && 
                                _schoolType != null && 
                                _studyFocus.isNotEmpty;
                  } else if (_currentStep == 2) {
                    canProceed = _scienceSubjects.isNotEmpty;
                  }
                  
                  if (canProceed) {
                    _nextStep();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please complete all required fields'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
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
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Complete Registration' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
