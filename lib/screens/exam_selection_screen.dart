import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'subject_selection_screen.dart';

class ExamSelectionScreen extends StatefulWidget {
  final UserModel userModel;

  const ExamSelectionScreen({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  State<ExamSelectionScreen> createState() => _ExamSelectionScreenState();
}

class _ExamSelectionScreenState extends State<ExamSelectionScreen> {
  String? _selectedExam;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _examTypes = [
    {
      'name': 'WAEC',
      'fullName': 'West African Examinations Council',
      'description': 'Senior Secondary Certificate Examination',
      'icon': Icons.school,
      'color': Colors.blue,
    },
    {
      'name': 'JAMB',
      'fullName': 'Joint Admissions and Matriculation Board',
      'description': 'Unified Tertiary Matriculation Examination',
      'icon': Icons.library_books,
      'color': Colors.green,
    },
    {
      'name': 'NECO',
      'fullName': 'National Examinations Council',
      'description': 'Senior School Certificate Examination',
      'icon': Icons.book,
      'color': Colors.orange,
    },
    {
      'name': 'NABTEB',
      'fullName': 'National Business and Technical Examinations Board',
      'description': 'National Business Certificate & National Technical Certificate',
      'icon': Icons.business,
      'color': Colors.purple,
    },
    {
      'name': 'GCE',
      'fullName': 'General Certificate of Education',
      'description': 'Advanced Level Examinations',
      'icon': Icons.workspace_premium,
      'color': Colors.red,
    },
  ];

  Future<void> _selectExam(String examType) async {
    setState(() {
      _selectedExam = examType;
      _isLoading = true;
    });

    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 500));

    widget.userModel.examType = examType;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected $examType'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to subject selection
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SubjectSelectionScreen(userModel: widget.userModel),
        ),
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
        title: const Text('Select Exam Type'),
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
                  Icons.quiz,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Choose Your Exam',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Select the examination you\'re preparing for',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Exam Type Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: _examTypes.length,
                    itemBuilder: (context, index) {
                      final exam = _examTypes[index];
                      final isSelected = _selectedExam == exam['name'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          elevation: 4,
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading ? null : () => _selectExam(exam['name']),
                            child: Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: exam['color'].withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      exam['icon'],
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam['name'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          exam['fullName'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          exam['description'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
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
                                      size: 24,
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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