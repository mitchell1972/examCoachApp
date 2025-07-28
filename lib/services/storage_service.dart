import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'registered_user';
  static const String _registrationStatusKey = 'registration_status';
  
  final Logger _logger = Logger();

  // Save user registration data
  Future<void> saveRegistration(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _userKey, value: userJson);
      await _storage.write(key: _registrationStatusKey, value: 'completed');
      _logger.i('✅ User registration saved successfully');
    } catch (e) {
      _logger.e('❌ Failed to save registration: $e');
      throw Exception('Failed to save registration data');
    }
  }

  // Get registered user data
  Future<UserModel?> getRegisteredUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) {
        _logger.i('ℹ️ No registered user found');
        return null;
      }
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel.fromJson(userMap);
      _logger.i('✅ Retrieved registered user: ${user.phoneNumber}');
      return user;
    } catch (e) {
      _logger.e('❌ Failed to retrieve registered user: $e');
      return null;
    }
  }

  // Check if user is registered
  Future<bool> isUserRegistered() async {
    try {
      final status = await _storage.read(key: _registrationStatusKey);
      final user = await getRegisteredUser();
      return status == 'completed' && user != null;
    } catch (e) {
      _logger.e('❌ Failed to check registration status: $e');
      return false;
    }
  }

  // Clear registration data (for forgot phone flow)
  Future<void> clearRegistration() async {
    try {
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _registrationStatusKey);
      _logger.i('✅ Registration data cleared');
    } catch (e) {
      _logger.e('❌ Failed to clear registration: $e');
      throw Exception('Failed to clear registration data');
    }
  }

  // Update user data (for profile updates)
  Future<void> updateUser(UserModel user) async {
    try {
      await saveRegistration(user);
      _logger.i('✅ User data updated successfully');
    } catch (e) {
      _logger.e('❌ Failed to update user: $e');
      throw Exception('Failed to update user data');
    }
  }

  // Get registration status
  Future<String?> getRegistrationStatus() async {
    try {
      return await _storage.read(key: _registrationStatusKey);
    } catch (e) {
      _logger.e('❌ Failed to get registration status: $e');
      return null;
    }
  }

  // Set registration status
  Future<void> setRegistrationStatus(String status) async {
    try {
      await _storage.write(key: _registrationStatusKey, value: status);
      _logger.i('✅ Registration status set to: $status');
    } catch (e) {
      _logger.e('❌ Failed to set registration status: $e');
      throw Exception('Failed to set registration status');
    }
  }

  // Save user registration data from Map (for testing)
  Future<void> saveRegisteredUser(Map<String, dynamic> userData) async {
    try {
      final user = UserModel.fromJson(userData);
      await saveRegistration(user);
      _logger.i('✅ User registration saved from map data');
    } catch (e) {
      _logger.e('❌ Failed to save user from map: $e');
      throw Exception('Failed to save user registration data');
    }
  }
}
