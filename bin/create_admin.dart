#!/usr/bin/env dart

import 'dart:io';
import '../lib/services/admin_service.dart';
import '../lib/services/database_service_rest.dart';

void main(List<String> args) async {
  print('🚀 Admin User Creation Tool');
  print('============================\n');

  // Parse command line arguments or prompt for input
  String? phoneNumber;
  String? fullName;
  String? email;
  String? password;
  String userRole = 'admin';

  if (args.length >= 4) {
    phoneNumber = args[0];
    fullName = args[1];
    email = args[2];
    password = args[3];
    if (args.length > 4) {
      userRole = args[4];
    }
  } else {
    // Interactive mode
    stdout.write('Enter phone number (e.g., +447405647247): ');
    phoneNumber = stdin.readLineSync();
    
    stdout.write('Enter full name (e.g., admin): ');
    fullName = stdin.readLineSync();
    
    stdout.write('Enter email (e.g., admin@examcoach.com): ');
    email = stdin.readLineSync();
    
    stdout.write('Enter password: ');
    password = stdin.readLineSync();
    
    stdout.write('Enter user role (admin/super_admin) [admin]: ');
    final roleInput = stdin.readLineSync();
    if (roleInput?.isNotEmpty == true) {
      userRole = roleInput!;
    }
  }

  // Validate inputs
  if (phoneNumber?.isEmpty != false ||
      fullName?.isEmpty != false ||
      email?.isEmpty != false ||
      password?.isEmpty != false) {
    print('❌ Error: All fields are required');
    print('Usage: dart run bin/create_admin.dart <phone> <name> <email> <password> [role]');
    exit(1);
  }

  try {
    print('\n🔧 Initializing services...');
    
    // Initialize services
    final adminService = AdminService();
    await adminService.initialize();
    
    // Configure database for testing (demo mode)
    final databaseService = DatabaseServiceRest();
    databaseService.configureForTesting();
    
    print('✅ Services initialized');
    print('\n👑 Creating admin user...');
    print('   Phone: $phoneNumber');
    print('   Name: $fullName');
    print('   Email: $email');
    print('   Role: $userRole');
    
    // Create the admin user
    final adminUser = await adminService.createAdminUser(
      phoneNumber: phoneNumber!,
      fullName: fullName!,
      email: email!,
      password: password!,
      userRole: userRole,
    );
    
    if (adminUser != null) {
      print('\n✅ Successfully created admin user!');
      print('📝 User Details:');
      print('   ID: ${adminUser.id}');
      print('   Phone: ${adminUser.phoneNumber}');
      print('   Name: ${adminUser.fullName}');
      print('   Email: ${adminUser.email}');
      print('   Role: ${adminUser.userRole}');
      print('   Account Status: ${adminUser.isAccountActive ? "Active" : "Inactive"}');
      print('   Registration Status: ${adminUser.registrationStatus}');
      print('\n🎉 Admin user is ready to use!');
      print('📱 Login Credentials:');
      print('   Phone: ${adminUser.phoneNumber}');
      print('   Password: [as provided]');
    } else {
      print('❌ Failed to create admin user');
      exit(1);
    }
    
  } catch (e) {
    print('❌ Error creating admin user: $e');
    exit(1);
  }
}