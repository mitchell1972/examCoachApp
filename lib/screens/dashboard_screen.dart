import 'package:flutter/material.dart';
import '../models/user_model.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel userModel;

  const DashboardScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _getExamDisplayText() {
    // Prioritize studyFocus as the primary exam types
    if (widget.userModel.studyFocus.isNotEmpty) {
      String examTypes = widget.userModel.studyFocus.join(' & ');
      // Add current class info if available
      if (widget.userModel.currentClass != null && widget.userModel.currentClass != 'Other') {
        examTypes += ' (${widget.userModel.currentClass})';
      }
      return examTypes;
    }
    
    // Fall back to examTypes if available
    if (widget.userModel.examTypes.isNotEmpty) {
      return widget.userModel.examTypes.join(' & ');
    }
    
    // Fall back to currentClass if available
    if (widget.userModel.currentClass != null) {
      return widget.userModel.currentClass!;
    }
    
    return widget.userModel.examType ?? 'N/A';
  }

  String _getSubjectDisplayText() {
    // Prioritize scienceSubjects as the primary subjects
    if (widget.userModel.scienceSubjects.isNotEmpty) {
      return widget.userModel.scienceSubjects.join(' & ');
    }
    
    // Fall back to subjects if available
    if (widget.userModel.subjects.isNotEmpty) {
      return widget.userModel.subjects.join(' & ');
    }
    
    return widget.userModel.subject ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Header
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                
                // Trial Badge
                _buildTrialBadge(),
                const SizedBox(height: 24),
                
                // Account Info Card
                _buildAccountInfoCard(),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(),
                
                const Spacer(),
                
                // Start Quiz Button
                _buildStartQuizButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        const Icon(
          Icons.dashboard,
          size: 60,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to Exam Coach!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.95),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Phone: ${widget.userModel.phoneNumber}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          'Exam: ${_getExamDisplayText()}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialBadge() {
    // Get trial display message
    final trialMessage = widget.userModel.trialDisplayMessage;
    final isOnTrial = widget.userModel.isOnTrial;
    final isExpired = widget.userModel.isTrialExpired;
    
    // If no trial data, don't show the badge
    if (trialMessage == null) {
      return const SizedBox.shrink();
    }
    
    // Determine colors based on trial status
    Color badgeColor = Colors.orange;
    Color iconColor = Colors.orange;
    IconData icon = Icons.access_time;
    
    if (isExpired) {
      badgeColor = Colors.red;
      iconColor = Colors.red;
      icon = Icons.timer_off;
    } else if (isOnTrial) {
      badgeColor = Colors.green;
      iconColor = Colors.green;
      icon = Icons.access_time;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Trial Expired' : '48h Free Trial',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trialMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.userModel.status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Phone', widget.userModel.phoneNumber ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Exam Type', _getExamDisplayText()),
          const SizedBox(height: 8),
          _buildInfoRow('Subject', _getSubjectDisplayText()),
          const SizedBox(height: 8),
          _buildInfoRow('School Type', widget.userModel.schoolType ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Status', widget.userModel.status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Practice Quiz',
                Icons.quiz,
                Colors.blue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz feature coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Study Materials',
                Icons.book,
                Colors.green,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study materials coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartQuizButton() {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Starting ${_getSubjectDisplayText()} quiz for ${_getExamDisplayText()}...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Start Your First Quiz',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
