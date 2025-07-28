import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final UserModel userModel;

  const SubjectSelectionScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  List<String> _selectedSubjects = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Mathematics',
      'shortName': 'Math',
      'icon': Icons.calculate,
      'color': Colors.blue,
      'description': 'Algebra, Geometry, Calculus & Statistics',
    },
    {
      'name': 'English Language',
      'shortName': 'English',
      'icon': Icons.book,
      'color': Colors.green,
      'description': 'Grammar, Comprehension & Essay Writing',
    },
    {
      'name': 'Physics',
      'shortName': 'Physics',
      'icon': Icons.science,
      'color': Colors.orange,
      'description': 'Mechanics, Electricity & Modern Physics',
    },
    {
      'name': 'Chemistry',
      'shortName': 'Chemistry',
      'icon': Icons.biotech,
      'color': Colors.purple,
      'description': 'Organic, Inorganic & Physical Chemistry',
    },
    {
      'name': 'Biology',
      'shortName': 'Biology',
      'icon': Icons.eco,
      'color': Colors.teal,
      'description': 'Botany, Zoology & Ecology',
    },
    {
      'name': 'Economics',
      'shortName': 'Economics',
      'icon': Icons.trending_up,
      'color': Colors.red,
      'description': 'Micro & Macro Economics',
    },
    {
      'name': 'Geography',
      'shortName': 'Geography',
      'icon': Icons.public,
      'color': Colors.brown,
      'description': 'Physical & Human Geography',
    },
    {
      'name': 'History',
      'shortName': 'History',
      'icon': Icons.history_edu,
      'color': Colors.indigo,
      'description': 'World History & Nigerian History',
    },
  ];

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  Future<void> _finishSetup() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate processing and account creation
    await Future.delayed(const Duration(seconds: 2));

    // Set both new and legacy fields
    widget.userModel.subjects = List<String>.from(_selectedSubjects);
    widget.userModel.subject = _selectedSubjects.first; // For backward compatibility
    widget.userModel.status = 'trial';
    widget.userModel.trialEndTime = DateTime.now().add(const Duration(hours: 48));

    if (mounted) {
      final examText = widget.userModel.examTypes.isNotEmpty 
          ? widget.userModel.examTypes.join(' & ')
          : widget.userModel.examType ?? 'Unknown';
      final subjectText = _selectedSubjects.join(' & ');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Exam: $examText, Subjects: $subjectText'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userModel: widget.userModel),
        ),
        (route) => false,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Subject'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                const Icon(
                  Icons.subject,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Choose Your Subject',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Select subjects for ${widget.userModel.examType} preparation (tap multiple)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Subject Cards
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final isSelected = _selectedSubjects.contains(subject['name']);
                      
                      return Material(
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading ? null : () => _toggleSubject(subject['name']),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: subject['color'].withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    subject['icon'],
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                Text(
                                  subject['shortName'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                
                                Text(
                                  subject['description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                if (_isLoading && isSelected)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                else if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Finish Button
                if (_selectedSubjects.isNotEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _finishSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Finish Setup (${_selectedSubjects.length} selected)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
