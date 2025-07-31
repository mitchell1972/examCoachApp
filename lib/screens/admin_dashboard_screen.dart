import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Logger _logger = Logger();
  final AdminService _adminService = AdminService();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Map<String, int> _userStats = {};
  UserModel? _currentAdmin;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, disabled, admin, trial, subscribed

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if admin is logged in
      final isLoggedIn = await _adminService.isAdminLoggedIn();
      if (!isLoggedIn) {
        _redirectToLogin();
        return;
      }

      // Get current admin
      _currentAdmin = await _adminService.getCurrentAdmin();

      // Load all users and statistics
      final users = await _adminService.getAllUsers();
      final stats = await _adminService.getUserStatistics();

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _userStats = stats;
        _isLoading = false;
      });

      _logger.i('✅ Admin dashboard loaded with ${users.length} users');
    } catch (e) {
      _logger.e('❌ Failed to load dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  void _filterUsers() {
    setState(() {
      List<UserModel> filtered = _allUsers;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((user) {
          final query = _searchQuery.toLowerCase();
          return (user.fullName?.toLowerCase().contains(query) ?? false) ||
                 (user.phoneNumber?.toLowerCase().contains(query) ?? false) ||
                 (user.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Apply category filter
      switch (_selectedFilter) {
        case 'active':
          filtered = filtered.where((user) => user.isAccountActive).toList();
          break;
        case 'disabled':
          filtered = filtered.where((user) => !user.isAccountActive).toList();
          break;
        case 'admin':
          filtered = filtered.where((user) => user.isAdmin).toList();
          break;
        case 'trial':
          filtered = filtered.where((user) => user.isOnTrial).toList();
          break;
        case 'subscribed':
          filtered = filtered.where((user) => user.hasActiveSubscription).toList();
          break;
        default: // 'all'
          break;
      }

      _filteredUsers = filtered;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _adminService.logoutAdmin();
      _redirectToLogin();
    }
  }

  Future<void> _toggleUserAccountStatus(UserModel user) async {
    final action = user.isAccountActive ? 'disable' : 'enable';
    final reason = await _showReasonDialog(action, user);
    
    if (reason == null) return; // User cancelled

    try {
      bool success;
      if (user.isAccountActive) {
        success = await _adminService.disableUserAccount(user.phoneNumber!, reason);
      } else {
        success = await _adminService.enableUserAccount(user.phoneNumber!, reason);
      }

      if (success) {
        _showSuccessMessage('User account ${action}d successfully');
        await _loadDashboardData(); // Refresh data
      } else {
        _showErrorMessage('Failed to $action user account');
      }
    } catch (e) {
      _logger.e('❌ Failed to $action user account: $e');
      _showErrorMessage('Error occurred while ${action}ing account');
    }
  }

  Future<String?> _showReasonDialog(String action, UserModel user) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user.fullName ?? user.phoneNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Reason for ${action}ing account',
                hintText: 'Enter reason...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop(reason);
              }
            },
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Full Name', user.fullName ?? 'N/A'),
              _buildDetailRow('Phone Number', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Email', user.email ?? 'N/A'),
              _buildDetailRow('Role', user.userRole),
              _buildDetailRow('Account Status', user.accountStatusDisplay),
              _buildDetailRow('Registration Status', user.registrationStatus),
              _buildDetailRow('Current Class', user.currentClass ?? 'N/A'),
              _buildDetailRow('School Type', user.schoolType ?? 'N/A'),
              _buildDetailRow('Study Focus', user.studyFocus.join(', ')),
              _buildDetailRow('Science Subjects', user.scienceSubjects.join(', ')),
              _buildDetailRow('Registration Date', 
                user.registrationDate?.toString().split(' ')[0] ?? 'N/A'),
              _buildDetailRow('Last Login', 
                user.lastLoginDate?.toString().split(' ')[0] ?? 'N/A'),
              _buildDetailRow('Access Status', user.accessStatusMessage),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Users', _userStats['totalUsers'] ?? 0, Icons.people, Colors.blue),
        _buildStatCard('Active Users', _userStats['activeUsers'] ?? 0, Icons.check_circle, Colors.green),
        _buildStatCard('Disabled Users', _userStats['disabledUsers'] ?? 0, Icons.block, Colors.red),
        _buildStatCard('Admin Users', _userStats['adminUsers'] ?? 0, Icons.admin_panel_settings, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'Try adjusting your search or filter',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user.isAccountActive ? Colors.green : Colors.red,
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              user.fullName ?? user.phoneNumber ?? 'Unknown User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: user.isAccountActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.phoneNumber} • ${user.userRole}'),
                Text(
                  user.accountStatusDisplay,
                  style: TextStyle(
                    color: user.isAccountActive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    _showUserDetails(user);
                    break;
                  case 'toggle':
                    _toggleUserAccountStatus(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('View Details'),
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      user.isAccountActive ? Icons.block : Icons.check_circle,
                    ),
                    title: Text(
                      user.isAccountActive ? 'Disable Account' : 'Enable Account',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin info header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.deepPurple.withOpacity(0.1),
                    child: Text(
                      'Welcome, ${_currentAdmin?.fullName ?? 'Admin'} (${_currentAdmin?.userRole})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Statistics cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsCards(),
                  ),

                  // Search and filter
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search users...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterUsers();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Users')),
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                            DropdownMenuItem(value: 'admin', child: Text('Admins')),
                            DropdownMenuItem(value: 'trial', child: Text('Trial')),
                            DropdownMenuItem(value: 'subscribed', child: Text('Subscribed')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value ?? 'all';
                            });
                            _filterUsers();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Users list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Users (${_filteredUsers.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildUserList(),
                ],
              ),
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}