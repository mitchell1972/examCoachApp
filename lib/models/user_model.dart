class UserModel {
  String? id; // User ID from authentication service
  String? phoneNumber;
  String? verificationId;
  String? otpCode;
  String? examType; // Keep for backward compatibility
  String? subject; // Keep for backward compatibility
  List<String> examTypes; // New: Support multiple exam types
  List<String> subjects; // New: Support multiple subjects
  String status;
  DateTime? trialEndTime;
  String? name;
  String? email;
  String? examInterest;
  DateTime? examDate;
  int? studyHoursPerDay;
  String? targetScore;
  DateTime? createdAt;

  UserModel({
    this.id,
    this.phoneNumber,
    this.verificationId,
    this.otpCode,
    this.examType,
    this.subject,
    List<String>? examTypes,
    List<String>? subjects,
    this.status = 'trial',
    this.trialEndTime,
    this.name,
    this.email,
    this.examInterest,
    this.examDate,
    this.studyHoursPerDay,
    this.targetScore,
    this.createdAt,
  }) : examTypes = examTypes ?? [],
       subjects = subjects ?? [];

  bool get isTrialActive {
    if (trialEndTime == null) return false;
    return DateTime.now().isBefore(trialEndTime!);
  }

  String get trialTimeRemaining {
    if (trialEndTime == null) return '0h';
    final remaining = trialEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '0h';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'verificationId': verificationId,
      'otpCode': otpCode,
      'examType': examType,
      'subject': subject,
      'examTypes': examTypes,
      'subjects': subjects,
      'status': status,
      'trialEndTime': trialEndTime?.toIso8601String(),
      'name': name,
      'email': email,
      'examInterest': examInterest,
      'examDate': examDate?.toIso8601String(),
      'studyHoursPerDay': studyHoursPerDay,
      'targetScore': targetScore,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      verificationId: json['verificationId'],
      otpCode: json['otpCode'],
      examType: json['examType'],
      subject: json['subject'],
      examTypes: json['examTypes'] != null 
          ? List<String>.from(json['examTypes'])
          : [],
      subjects: json['subjects'] != null 
          ? List<String>.from(json['subjects'])
          : [],
      status: json['status'] ?? 'trial',
      trialEndTime: json['trialEndTime'] != null 
          ? DateTime.parse(json['trialEndTime'])
          : null,
      name: json['name'],
      email: json['email'],
      examInterest: json['examInterest'],
      examDate: json['examDate'] != null
          ? DateTime.parse(json['examDate'])
          : null,
      studyHoursPerDay: json['studyHoursPerDay'],
      targetScore: json['targetScore'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
