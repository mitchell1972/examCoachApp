import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

/// Firebase-free database service using Supabase REST API directly
/// Supports 200K+ users with proper scaling
class DatabaseServiceRest {
  static final DatabaseServiceRest _instance = DatabaseServiceRest._internal();
  factory DatabaseServiceRest() => _instance;
  DatabaseServiceRest._internal();

  final Logger _logger = Logger();
  
  // Supabase configuration
  String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';


  // HTTP headers for API calls
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
  };



  /// Create a new user in the database
  Future<UserModel?> createUser({
    required String phoneNumber,
    required String fullName,
    required String currentClass,
    required String schoolType,
    required List<String> studyFocus,
    required List<String> scienceSubjects,
    String? email,
  }) async {
    try {
      // Generate a unique ID for the user
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      final userData = {
        'id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'current_class': currentClass,
        'school_type': schoolType,
        'study_focus': studyFocus,
        'science_subjects': scienceSubjects,
        'exam_types': _mapStudyFocusToExamTypes(studyFocus),
        'subjects': scienceSubjects,
        'status': 'trial',
        'trial_start_date': DateTime.now().toIso8601String(),
        'trial_expires': DateTime.now().add(Duration(hours: 48)).toIso8601String(),
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/users'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        _logger.i('✅ User created successfully in database');
        return UserModel.fromJson(userData);
      } else {
        _logger.e('❌ Failed to create user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Database error creating user: $e');
      return null;
    }
  }

  /// Update existing user data
  Future<bool> updateUser(UserModel user) async {
    try {
      if (user.id == null) {
        _logger.w('⚠️ Cannot update user without ID');
        return false;
      }

      final userData = {
        'full_name': user.fullName,
        'phone_number': user.phoneNumber,
        'email': user.email,
        'current_class': user.currentClass,
        'school_type': user.schoolType,
        'study_focus': user.studyFocus,
        'science_subjects': user.scienceSubjects,
        'exam_types': user.examTypes,
        'subjects': user.subjects,
        'status': user.status,
        'trial_start_date': user.trialStartTime?.toIso8601String(),
        'trial_expires': user.trialEndTime?.toIso8601String(),
        'is_verified': user.isVerified,
        'last_login_date': user.lastLoginDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/users?id=eq.${user.id}'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 204) {
        _logger.i('✅ User updated successfully in database');
        return true;
      } else {
        _logger.e('❌ Failed to update user: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Database error updating user: $e');
      return false;
    }
  }

  /// Get user by email address
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/users?email=eq.$email'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        if (users.isNotEmpty) {
          _logger.i('✅ User found in database by email');
          return UserModel.fromJson(users.first);
        } else {
          _logger.i('ℹ️ No user found with email: $email');
          return null;
        }
      } else {
        _logger.e('❌ Failed to get user by email: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Database error getting user by email: $e');
      return null;
    }
  }

  /// Get user by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/users?phone_number=eq.$phoneNumber'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        if (users.isNotEmpty) {
          _logger.i('✅ User found in database');
          return UserModel.fromJson(users.first);
        } else {
          _logger.i('ℹ️ No user found with phone number: $phoneNumber');
          return null;
        }
      } else {
        _logger.e('❌ Failed to get user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Database error getting user: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/users?id=eq.$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        if (users.isNotEmpty) {
          _logger.i('✅ User found in database');
          return UserModel.fromJson(users.first);
        } else {
          _logger.i('ℹ️ No user found with ID: $userId');
          return null;
        }
      } else {
        _logger.e('❌ Failed to get user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Database error getting user: $e');
      return null;
    }
  }

  /// Check if database is healthy (for monitoring)
  Future<bool> isHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ Database health check failed: $e');
      return false;
    }
  }

  /// Helper method to map study focus to exam types
  List<String> _mapStudyFocusToExamTypes(List<String> studyFocus) {
    return studyFocus.map((focus) {
      switch (focus) {
        case 'JAMB':
          return 'JAMB';
        case 'WAEC':
          return 'WAEC';
        case 'NECO':
          return 'NECO';
        case 'Subject Mastery':
          return 'Subject Mastery';
        case 'General Review':
          return 'General Review';
        default:
          return focus;
      }
    }).toList();
  }
} 