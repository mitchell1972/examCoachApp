import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';
import 'error_handler.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient get _client => SupabaseConfig.client;
  GoTrueClient get _auth => SupabaseConfig.auth;

  // User Management
  
  /// Create a new user with phone authentication
  Future<UserModel?> createUserWithPhone({
    required String phoneNumber,
    required String fullName,
    required String currentClass,
    required String schoolType,
    required List<String> studyFocus,
    required List<String> scienceSubjects,
    String? email,
  }) async {
    try {
      // Sign up with phone (OTP will be sent)
      final AuthResponse response = await _auth.signUp(
        phone: phoneNumber,
        password: _generateRandomPassword(), // Required parameter, but not used for phone auth
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Create user profile in our custom table
        final userData = {
          'id': response.user!.id,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'email': email,
          'current_class': currentClass,
          'school_type': schoolType,
          'study_focus': studyFocus,
          'science_subjects': scienceSubjects,
          'exam_types': _mapStudyFocusToExamTypes(studyFocus),
          'subjects': scienceSubjects,
          'exam_type': studyFocus.isNotEmpty ? studyFocus.first : null,
          'subject': scienceSubjects.isNotEmpty ? scienceSubjects.first : null,
          'status': 'trial',
          'trial_start_date': DateTime.now().toIso8601String(),
          'trial_expires': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
          'is_verified': false,
        };

        await _client.from('users').insert(userData);

        return UserModel.fromJson({
          ...userData,
          'phoneNumber': phoneNumber,
          'examTypes': _mapStudyFocusToExamTypes(studyFocus),
          'subjects': scienceSubjects,
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to create user with phone');
      rethrow;
    }
    return null;
  }

  /// Create a new user with username and password
  Future<UserModel?> createUserWithPassword({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String currentClass,
    required String schoolType,
    required List<String> studyFocus,
    required List<String> scienceSubjects,
  }) async {
    try {
      // Check if username is available
      final existingUser = await _client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Username already exists');
      }

      // Sign up with email and password
      final AuthResponse response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Create user profile in our custom table
        final userData = {
          'id': response.user!.id,
          'username': username,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'email': email,
          'current_class': currentClass,
          'school_type': schoolType,
          'study_focus': studyFocus,
          'science_subjects': scienceSubjects,
          'exam_types': _mapStudyFocusToExamTypes(studyFocus),
          'subjects': scienceSubjects,
          'exam_type': studyFocus.isNotEmpty ? studyFocus.first : null,
          'subject': scienceSubjects.isNotEmpty ? scienceSubjects.first : null,
          'status': 'trial',
          'trial_start_date': DateTime.now().toIso8601String(),
          'trial_expires': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
          'is_verified': false,
        };

        await _client.from('users').insert(userData);

        return UserModel.fromJson({
          ...userData,
          'phoneNumber': phoneNumber,
          'examTypes': _mapStudyFocusToExamTypes(studyFocus),
          'subjects': scienceSubjects,
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to create user with password');
      rethrow;
    }
    return null;
  }

  /// Verify OTP for phone authentication
  Future<UserModel?> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final AuthResponse response = await _auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null) {
        // Update user as verified
        await _client
            .from('users')
            .update({
              'is_verified': true,
              'last_login_date': DateTime.now().toIso8601String(),
            })
            .eq('id', response.user!.id);

        return await getUserById(response.user!.id);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to verify OTP');
      rethrow;
    }
    return null;
  }

  /// Sign in with username and password
  Future<UserModel?> signInWithPassword({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      String email = usernameOrEmail;
      
      // If it's a username, get the email first
      if (!usernameOrEmail.contains('@')) {
        final userRecord = await _client
            .from('users')
            .select('email')
            .eq('username', usernameOrEmail)
            .single();
        email = userRecord['email'];
      }

      final AuthResponse response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Update last login
        await _client
            .from('users')
            .update({
              'last_login_date': DateTime.now().toIso8601String(),
            })
            .eq('id', response.user!.id);

        return await getUserById(response.user!.id);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to sign in with password');
      rethrow;
    }
    return null;
  }

  /// Sign in with phone OTP
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _auth.signInWithOtp(phone: phoneNumber);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to send OTP');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson({
        ...response,
        'phoneNumber': response['phone_number'],
        'examTypes': List<String>.from(response['exam_types'] ?? []),
        'subjects': List<String>.from(response['subjects'] ?? []),
        'studyFocus': List<String>.from(response['study_focus'] ?? []),
        'scienceSubjects': List<String>.from(response['science_subjects'] ?? []),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user by ID');
      return null;
    }
  }

  /// Get user by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson({
        ...response,
        'phoneNumber': response['phone_number'],
        'examTypes': List<String>.from(response['exam_types'] ?? []),
        'subjects': List<String>.from(response['subjects'] ?? []),
        'studyFocus': List<String>.from(response['study_focus'] ?? []),
        'scienceSubjects': List<String>.from(response['science_subjects'] ?? []),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user by phone');
      return null;
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson({
        ...response,
        'phoneNumber': response['phone_number'],
        'examTypes': List<String>.from(response['exam_types'] ?? []),
        'subjects': List<String>.from(response['subjects'] ?? []),
        'studyFocus': List<String>.from(response['study_focus'] ?? []),
        'scienceSubjects': List<String>.from(response['science_subjects'] ?? []),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user by username');
      return null;
    }
  }

  /// Update user profile
  Future<UserModel?> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('users')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return await getUserById(userId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to update user');
      rethrow;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to check username availability');
      return false;
    }
  }

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await getUserById(user.id);
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get current user');
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to sign out');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from custom table first
      await _client.from('users').delete().eq('id', userId);
      
      // Delete from auth (requires admin privileges or user session)
      await _auth.admin.deleteUser(userId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to delete user');
      rethrow;
    }
  }

  // Session Management

  /// Create user session
  Future<void> createSession(String userId, Map<String, dynamic> deviceInfo) async {
    try {
      final sessionToken = const Uuid().v4();
      
      await _client.from('user_sessions').insert({
        'user_id': userId,
        'session_token': sessionToken,
        'device_info': deviceInfo,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to create session');
    }
  }

  /// Get active sessions for user
  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    try {
      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String());

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user sessions');
      return [];
    }
  }

  /// Revoke session
  Future<void> revokeSession(String sessionToken) async {
    try {
      await _client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('session_token', sessionToken);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to revoke session');
    }
  }

  // User Preferences

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user preferences');
      return null;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final existing = await getUserPreferences(userId);
      
      if (existing != null) {
        await _client
            .from('user_preferences')
            .update({
              ...preferences,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await _client.from('user_preferences').insert({
          'user_id': userId,
          ...preferences,
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to update user preferences');
      rethrow;
    }
  }

  // Analytics and Monitoring

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final totalUsersResponse = await _client
          .from('users')
          .select('id')
          .count(CountOption.exact);

      final activeUsersResponse = await _client
          .from('users')
          .select('id')
          .gte('last_login_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .count(CountOption.exact);

      final trialUsersResponse = await _client
          .from('users')
          .select('id')
          .eq('status', 'trial')
          .count(CountOption.exact);

      return {
        'total_users': totalUsersResponse.count,
        'active_users': activeUsersResponse.count,
        'trial_users': trialUsersResponse.count,
      };
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace as StackTrace?, context: 'Failed to get user stats');
      return {};
    }
  }

  // Helper Methods

  /// Generate a random password for phone authentication
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(16, (index) => chars[(random + index) % chars.length]).join();
  }

  List<String> _mapStudyFocusToExamTypes(List<String> studyFocus) {
    final examTypes = <String>[];
    for (final focus in studyFocus) {
      switch (focus.toLowerCase()) {
        case 'waec':
        case 'west african examinations council':
          examTypes.add('WAEC');
          break;
        case 'jamb':
        case 'joint admissions and matriculation board':
          examTypes.add('JAMB');
          break;
        case 'both':
          examTypes.addAll(['WAEC', 'JAMB']);
          break;
        default:
          examTypes.add(focus);
      }
    }
    return examTypes.toSet().toList(); // Remove duplicates
  }

}
