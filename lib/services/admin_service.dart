import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'database_service_rest.dart';

class AdminService {
  static const _storage = FlutterSecureStorage();
  static const String _adminSessionKey = 'admin_session';
  
  final Logger _logger = Logger();
  final StorageService _storageService = StorageService();
  final DatabaseServiceRest _databaseService = DatabaseServiceRest();
  
  // Test mode - use in-memory storage instead of secure storage
  static bool _isTestMode = false;
  static UserModel? _testCurrentAdmin;
  static String? _testAdminSession;
  
  // Default admin credentials for demo/development
  static const String defaultAdminPhone = '+2348000000000';
  static const String defaultAdminPassword = 'admin123456';
  
  /// Enable test mode - use in-memory storage instead of secure storage
  static void enableTestMode() {
    _isTestMode = true;
    _testCurrentAdmin = null;
    _testAdminSession = null;
  }
  
  /// Disable test mode - use secure storage
  static void disableTestMode() {
    _isTestMode = false;
    _testCurrentAdmin = null;
    _testAdminSession = null;
  }
  
  /// Initialize admin service and create default admin if needed
  Future<void> initialize() async {
    try {
      _logger.i('🔧 Initializing admin service...');
      
      // Check if default admin exists
      final existingAdmin = await _getDefaultAdmin();
      if (existingAdmin == null) {
        await _createDefaultAdmin();
      }
      
      // Ensure specific admin user has correct credentials
      await _createSpecificAdmin();
      
      _logger.i('✅ Admin service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize admin service: $e');
    }
  }
  
  /// Create default admin user for initial setup
  Future<void> _createDefaultAdmin() async {
    try {
      final defaultAdmin = UserModel(
        id: 'admin_001',
        phoneNumber: defaultAdminPhone,
        fullName: 'System Administrator',
        email: 'admin@examcoach.com',
        userRole: 'super_admin',
        isAccountActive: true,
        isRegistered: true,
        isVerified: true,
        registrationDate: DateTime.now(),
        registrationStatus: 'completed',
      );
      
      // Set admin password
      defaultAdmin.setPassword(defaultAdminPassword);
      
      // Configure database service for testing if needed
      _databaseService.configureForTesting();
      
      // Add to mock database for demo mode
      _databaseService.addMockUser(defaultAdmin);
      
      _logger.i('✅ Default admin created: $defaultAdminPhone');
    } catch (e) {
      _logger.e('❌ Failed to create default admin: $e');
    }
  }

  /// Create specific admin user with production credentials
  Future<void> _createSpecificAdmin() async {
    try {
      const specificPhone = '+447405647247';
      const specificPassword = '@dm1n19661972';
      
      _logger.i('🔍 Checking for specific admin: $specificPhone');
      
      // Check if specific admin already exists
      final existingSpecificAdmin = await _databaseService.getUserByPhone(specificPhone);
      if (existingSpecificAdmin != null) {
        _logger.i('🔍 Specific admin already exists, deleting first...');
        _databaseService.deleteMockUserByPhone(specificPhone);
      }
      
      // Create specific admin user
      final specificAdmin = await createAdminUser(
        phoneNumber: specificPhone,
        fullName: 'admin',
        email: 'admin@examcoach.com',
        password: specificPassword,
        userRole: 'super_admin',
      );
      
      if (specificAdmin != null) {
        _logger.i('✅ Specific admin created: $specificPhone with username "admin"');
      } else {
        _logger.e('❌ Failed to create specific admin');
      }
    } catch (e) {
      _logger.e('❌ Failed to create specific admin: $e');
    }
  }
  

  
  /// Get default admin user
  Future<UserModel?> _getDefaultAdmin() async {
    try {
      return await _databaseService.getUserByPhone(defaultAdminPhone);
    } catch (e) {
      _logger.w('⚠️ Could not get default admin: $e');
      return null;
    }
  }
  
  /// Authenticate admin user
  Future<UserModel?> authenticateAdmin(String phoneNumber, String password) async {
    try {
      _logger.i('🔐 Attempting admin authentication for: $phoneNumber');
      
      // Get user by phone number
      final user = await _databaseService.getUserByPhone(phoneNumber);
      if (user == null) {
        _logger.w('⚠️ Admin user not found: $phoneNumber');
        return null;
      }
      
      // Check if user is admin
      if (!user.isAdmin) {
        _logger.w('⚠️ User is not admin: $phoneNumber');
        return null;
      }
      
      // Check if account is active
      if (!user.isAccountActive) {
        _logger.w('⚠️ Admin account is disabled: $phoneNumber');
        return null;
      }
      
      // Verify password
      if (!user.verifyPassword(password)) {
        _logger.w('⚠️ Invalid admin password for: $phoneNumber');
        return null;
      }
      
      // Update last login date
      user.lastLoginDate = DateTime.now();
      
      // Save admin session
      await _saveAdminSession(user);
      
      _logger.i('✅ Admin authenticated successfully: $phoneNumber');
      return user;
    } catch (e) {
      _logger.e('❌ Admin authentication failed: $e');
      return null;
    }
  }
  
  /// Save admin session
  Future<void> _saveAdminSession(UserModel admin) async {
    try {
      final sessionData = {
        'adminId': admin.id,
        'phoneNumber': admin.phoneNumber,
        'userRole': admin.userRole,
        'loginTime': DateTime.now().toIso8601String(),
      };
      
      if (_isTestMode) {
        // In test mode, use in-memory storage
        _testCurrentAdmin = admin;
        _testAdminSession = jsonEncode(sessionData);
        _logger.i('✅ Admin session saved (test mode)');
      } else {
        // Normal mode, use secure storage
        await _storage.write(
          key: _adminSessionKey,
          value: jsonEncode(sessionData),
        );
        _logger.i('✅ Admin session saved');
      }
    } catch (e) {
      _logger.e('❌ Failed to save admin session: $e');
    }
  }
  
  /// Get current admin session
  Future<Map<String, dynamic>?> getCurrentAdminSession() async {
    try {
      if (_isTestMode) {
        // In test mode, use in-memory storage
        if (_testAdminSession == null) return null;
        return jsonDecode(_testAdminSession!) as Map<String, dynamic>;
      } else {
        // Normal mode, use secure storage
        final sessionJson = await _storage.read(key: _adminSessionKey);
        if (sessionJson == null) return null;
        return jsonDecode(sessionJson) as Map<String, dynamic>;
      }
    } catch (e) {
      _logger.e('❌ Failed to get admin session: $e');
      return null;
    }
  }
  
  /// Check if admin is currently logged in
  Future<bool> isAdminLoggedIn() async {
    final session = await getCurrentAdminSession();
    return session != null;
  }
  
  /// Get current admin user
  Future<UserModel?> getCurrentAdmin() async {
    try {
      final session = await getCurrentAdminSession();
      if (session == null) return null;
      
      final phoneNumber = session['phoneNumber'] as String?;
      if (phoneNumber == null) return null;
      
      return await _databaseService.getUserByPhone(phoneNumber);
    } catch (e) {
      _logger.e('❌ Failed to get current admin: $e');
      return null;
    }
  }
  
  /// Logout admin
  Future<void> logoutAdmin() async {
    try {
      if (_isTestMode) {
        // In test mode, clear in-memory storage
        _testCurrentAdmin = null;
        _testAdminSession = null;
        _logger.i('✅ Admin logged out successfully (test mode)');
      } else {
        // Normal mode, use secure storage
        await _storage.delete(key: _adminSessionKey);
        _logger.i('✅ Admin logged out successfully');
      }
    } catch (e) {
      _logger.e('❌ Failed to logout admin: $e');
    }
  }
  
  /// Get all registered users (for admin dashboard)
  Future<List<UserModel>> getAllUsers() async {
    try {
      _logger.i('📋 Getting all users for admin dashboard...');
      
      // In demo mode, get users from mock database
      final allUsers = <UserModel>[];
      
      // Get all mock users from database service
      final mockUsers = _databaseService.getAllMockUsers();
      allUsers.addAll(mockUsers);
      
      // Also get the registered user from storage service
      final registeredUser = await _storageService.getRegisteredUser();
      if (registeredUser != null) {
        // Check if this user is already in mock users (avoid duplicates)
        final isDuplicate = allUsers.any((user) => 
          user.phoneNumber == registeredUser.phoneNumber);
        
        if (!isDuplicate) {
          allUsers.add(registeredUser);
        }
      }
      
      // Sort users by registration date (newest first)
      allUsers.sort((a, b) {
        final dateA = a.registrationDate ?? DateTime(1970);
        final dateB = b.registrationDate ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      _logger.i('✅ Retrieved ${allUsers.length} users for admin dashboard');
      return allUsers;
    } catch (e) {
      _logger.e('❌ Failed to get all users: $e');
      return [];
    }
  }
  
  /// Enable user account
  Future<bool> enableUserAccount(String phoneNumber, String reason) async {
    try {
      final currentAdmin = await getCurrentAdmin();
      if (currentAdmin == null) {
        _logger.w('⚠️ No admin session found');
        return false;
      }
      
      _logger.i('✅ Enabling account for user: $phoneNumber');
      
      final user = await _databaseService.getUserByPhone(phoneNumber);
      if (user == null) {
        _logger.w('⚠️ User not found: $phoneNumber');
        return false;
      }
      
      // Enable account
      user.enableAccount(currentAdmin.id ?? 'unknown_admin');
      
      // Update user in database/storage
      await _updateUserInStorage(user);
      
      _logger.i('✅ User account enabled: $phoneNumber');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to enable user account: $e');
      return false;
    }
  }
  
  /// Disable user account
  Future<bool> disableUserAccount(String phoneNumber, String reason) async {
    try {
      final currentAdmin = await getCurrentAdmin();
      if (currentAdmin == null) {
        _logger.w('⚠️ No admin session found');
        return false;
      }
      
      _logger.i('⚠️ Disabling account for user: $phoneNumber');
      
      final user = await _databaseService.getUserByPhone(phoneNumber);
      if (user == null) {
        _logger.w('⚠️ User not found: $phoneNumber');
        return false;
      }
      
      // Disable account
      user.disableAccount(reason, currentAdmin.id ?? 'unknown_admin');
      
      // Update user in database/storage
      await _updateUserInStorage(user);
      
      _logger.i('✅ User account disabled: $phoneNumber');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to disable user account: $e');
      return false;
    }
  }
  
  /// Update user in storage/database
  Future<void> _updateUserInStorage(UserModel user) async {
    try {
      // Update in mock database
      _databaseService.updateMockUser(user);
      
      // If this is the currently registered user, update in storage as well
      final registeredUser = await _storageService.getRegisteredUser();
      if (registeredUser?.phoneNumber == user.phoneNumber) {
        await _storageService.updateUser(user);
      }
    } catch (e) {
      _logger.e('❌ Failed to update user in storage: $e');
    }
  }
  
  /// Get user statistics for admin dashboard
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers();
      
      final stats = {
        'totalUsers': allUsers.length,
        'activeUsers': allUsers.where((user) => user.isAccountActive).length,
        'disabledUsers': allUsers.where((user) => !user.isAccountActive).length,
        'registeredUsers': allUsers.where((user) => user.isRegistered).length,
        'verifiedUsers': allUsers.where((user) => user.isVerified).length,
        'adminUsers': allUsers.where((user) => user.isAdmin).length,
        'trialUsers': allUsers.where((user) => user.isOnTrial).length,
        'subscribedUsers': allUsers.where((user) => user.hasActiveSubscription).length,
      };
      
      return stats;
    } catch (e) {
      _logger.e('❌ Failed to get user statistics: $e');
      return {};
    }
  }
  
  /// Delete user by phone number
  Future<bool> deleteUserByPhone(String phoneNumber) async {
    try {
      _logger.i('🗑️ Attempting to delete user with phone: $phoneNumber');
      
      // Delete from mock database
      final deleted = _databaseService.deleteMockUserByPhone(phoneNumber);
      
      if (deleted) {
        // Also try to delete from secure storage if it's the registered user
        try {
          final registeredUser = await _storageService.getRegisteredUser();
          if (registeredUser?.phoneNumber == phoneNumber) {
            if (_isTestMode) {
              _logger.i('🗑️ Test mode: Skipping secure storage deletion');
            } else {
              await _storage.delete(key: 'registered_user');
              _logger.i('🗑️ Also deleted from secure storage');
            }
          }
        } catch (e) {
          _logger.w('⚠️ Could not check/delete from secure storage: $e');
        }
        
        _logger.i('✅ Successfully deleted user: $phoneNumber');
        return true;
      } else {
        _logger.w('⚠️ User not found for deletion: $phoneNumber');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Failed to delete user: $e');
      return false;
    }
  }
  
  /// Create admin user with specific details
  Future<UserModel?> createAdminUser({
    required String phoneNumber,
    required String fullName,
    required String email,
    required String password,
    String userRole = 'admin',
  }) async {
    try {
      _logger.i('👑 Creating admin user with phone: $phoneNumber');
      
      // First, check if user already exists and delete if necessary
      final existingUser = await _databaseService.getUserByPhone(phoneNumber);
      if (existingUser != null) {
        _logger.i('⚠️ User already exists, deleting first...');
        await deleteUserByPhone(phoneNumber);
      }
      
      // Create new admin user
      final adminUser = UserModel(
        id: 'admin_${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}',
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
        userRole: userRole,
        isAccountActive: true,
        isRegistered: true,
        isVerified: true,
        registrationDate: DateTime.now(),
        registrationStatus: 'completed',
        // Set some default academic info for admin
        currentClass: 'Admin',
        schoolType: 'Administration',
        studyFocus: ['Administration'],
        scienceSubjects: ['Administration'],
      );
      
      // Set password
      adminUser.setPassword(password);
      
      // Add to mock database
      _databaseService.addMockUser(adminUser);
      
      _logger.i('✅ Admin user created successfully: $phoneNumber');
      return adminUser;
    } catch (e) {
      _logger.e('❌ Failed to create admin user: $e');
      return null;
    }
  }
}