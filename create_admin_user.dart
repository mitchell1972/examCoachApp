import 'lib/services/admin_service.dart';
import 'lib/services/database_service_rest.dart';

void main() async {
  print('🚀 Creating admin user with phone +447405647247...');
  
  // Initialize services
  final adminService = AdminService();
  await adminService.initialize();
  
  // Configure database for testing (demo mode)
  final databaseService = DatabaseServiceRest();
  databaseService.configureForTesting();
  
  try {
    // Create the admin user
    final adminUser = await adminService.createAdminUser(
      phoneNumber: '+447405647247',
      fullName: 'Admin User',
      email: 'admin@examcoach.com',
      password: 'AdminPass123!',
      userRole: 'admin',
    );
    
    if (adminUser != null) {
      print('✅ Successfully created admin user:');
      print('   Phone: ${adminUser.phoneNumber}');
      print('   Name: ${adminUser.fullName}');
      print('   Email: ${adminUser.email}');
      print('   Role: ${adminUser.userRole}');
      print('   Account Active: ${adminUser.isAccountActive}');
      print('   Registered: ${adminUser.isRegistered}');
      print('   Verified: ${adminUser.isVerified}');
    } else {
      print('❌ Failed to create admin user');
    }
    
    // Verify the user was created by getting all users
    print('\n📋 Checking all users in database:');
    final allUsers = await adminService.getAllUsers();
    for (final user in allUsers) {
      print('   - ${user.fullName} (${user.phoneNumber}) - Role: ${user.userRole}');
    }
    
  } catch (e) {
    print('❌ Error creating admin user: $e');
  }
}