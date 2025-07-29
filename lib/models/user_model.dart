import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

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
  DateTime? trialStartTime; // New: Track when trial started
  String? name;
  String? email;
  String? examInterest;
  DateTime? examDate;
  int? studyHoursPerDay;
  String? targetScore;
  DateTime? createdAt;

  // Enhanced registration fields
  String? fullName;
  String? currentClass; // SS1, SS2, SS3, Graduate, Other
  String? schoolType; // Public, Private, Homeschool, Not in school
  List<String> studyFocus; // JAMB, WAEC, NECO, Subject Mastery, General Review
  List<String> scienceSubjects; // Math, Physics, Chemistry, Biology, etc.
  DateTime? targetExamDate;
  int? studyHoursPerWeek;
  List<String> difficultyAreas;
  
  // Password authentication
  String? _passwordHash; // Private: Hashed password storage
  String? passwordSalt; // Salt for password hashing
  
  // Registration tracking
  bool isRegistered;
  bool isVerified;
  DateTime? registrationDate;
  DateTime? lastLoginDate;
  String registrationStatus; // 'pending', 'completed', 'verified'

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
    this.trialStartTime,
    this.name,
    this.email,
    this.examInterest,
    this.examDate,
    this.studyHoursPerDay,
    this.targetScore,
    this.createdAt,
    // Enhanced registration fields
    this.fullName,
    this.currentClass,
    this.schoolType,
    List<String>? studyFocus,
    List<String>? scienceSubjects,
    this.targetExamDate,
    this.studyHoursPerWeek,
    List<String>? difficultyAreas,
    // Password authentication
    String? passwordHash,
    this.passwordSalt,
    // Registration tracking
    this.isRegistered = false,
    this.isVerified = false,
    this.registrationDate,
    this.lastLoginDate,
    this.registrationStatus = 'pending',
  }) : examTypes = examTypes ?? [],
       subjects = subjects ?? [],
       studyFocus = studyFocus ?? [],
       scienceSubjects = scienceSubjects ?? [],
       difficultyAreas = difficultyAreas ?? [],
       _passwordHash = passwordHash;

  // Password management methods
  void setPassword(String password) {
    if (password.isEmpty) {
      _passwordHash = null;
      passwordSalt = null;
      return;
    }
    
    // Generate a random salt
    passwordSalt = _generateSalt();
    // Hash the password with salt
    _passwordHash = _hashPassword(password, passwordSalt!);
  }
  
  bool verifyPassword(String password) {
    if (_passwordHash == null || passwordSalt == null) {
      return false;
    }
    
    final hashedInput = _hashPassword(password, passwordSalt!);
    return hashedInput == _passwordHash;
  }
  
  bool get hasPassword {
    return _passwordHash != null && _passwordHash!.isNotEmpty;
  }
  
  // Private helper methods
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }
  
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Trial functionality methods
  void setTrialStatus(DateTime signupTime) {
    trialStartTime = signupTime;
    trialEndTime = signupTime.add(const Duration(hours: 48));
    status = 'trial';
  }

  bool get isOnTrial {
    if (trialStartTime == null || trialEndTime == null) return false;
    if (isTrialExpired) return false;
    return true;
  }

  bool get isTrialExpired {
    if (trialEndTime == null) return false;
    return DateTime.now().isAfter(trialEndTime!);
  }

  DateTime? get trialExpires {
    return trialEndTime;
  }

  // Backward compatibility getter for tests
  DateTime? get trialStartDate {
    return trialStartTime;
  }

  Duration? get trialTimeRemaining {
    if (trialEndTime == null) return null;
    final remaining = trialEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }

  String? get trialDisplayMessage {
    if (trialStartTime == null || trialEndTime == null) return null;
    
    if (isTrialExpired) {
      return 'Trial expired';
    }
    
    // Format the expiry date and time
    final expiry = trialEndTime!;
    final formattedDate = '${expiry.day}/${expiry.month}/${expiry.year}';
    final formattedTime = '${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
    
    return 'Free trial ends at $formattedDate $formattedTime';
  }

  // Legacy methods for backward compatibility
  bool get isTrialActive {
    if (trialEndTime == null) return false;
    return DateTime.now().isBefore(trialEndTime!);
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
      'trialStartTime': trialStartTime?.toIso8601String(),
      'isOnTrial': isOnTrial,
      'trialExpires': trialExpires?.toIso8601String(),
      'name': name,
      'email': email,
      'examInterest': examInterest,
      'examDate': examDate?.toIso8601String(),
      'studyHoursPerDay': studyHoursPerDay,
      'targetScore': targetScore,
      'createdAt': createdAt?.toIso8601String(),
      // Enhanced registration fields
      'fullName': fullName,
      'currentClass': currentClass,
      'schoolType': schoolType,
      'studyFocus': studyFocus,
      'scienceSubjects': scienceSubjects,
      'targetExamDate': targetExamDate?.toIso8601String(),
      'studyHoursPerWeek': studyHoursPerWeek,
      'difficultyAreas': difficultyAreas,
      // Password authentication
      '_passwordHash': _passwordHash,
      'passwordSalt': passwordSalt,
      'hasPassword': hasPassword,
      // Registration tracking
      'isRegistered': isRegistered,
      'isVerified': isVerified,
      'registrationDate': registrationDate?.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'registrationStatus': registrationStatus,
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
          : (json['trialExpires'] != null 
              ? DateTime.parse(json['trialExpires'])
              : null),
      trialStartTime: json['trialStartTime'] != null 
          ? DateTime.parse(json['trialStartTime'])
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
      // Enhanced registration fields
      fullName: json['fullName'],
      currentClass: json['currentClass'],
      schoolType: json['schoolType'],
      studyFocus: json['studyFocus'] != null 
          ? List<String>.from(json['studyFocus'])
          : [],
      scienceSubjects: json['scienceSubjects'] != null 
          ? List<String>.from(json['scienceSubjects'])
          : [],
      targetExamDate: json['targetExamDate'] != null
          ? DateTime.parse(json['targetExamDate'])
          : null,
      studyHoursPerWeek: json['studyHoursPerWeek'],
      difficultyAreas: json['difficultyAreas'] != null 
          ? List<String>.from(json['difficultyAreas'])
          : [],
      // Password authentication
      passwordHash: json['_passwordHash'],
      passwordSalt: json['passwordSalt'],
      // Registration tracking
      isRegistered: json['isRegistered'] ?? false,
      isVerified: json['isVerified'] ?? false,
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : null,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
      registrationStatus: json['registrationStatus'] ?? 'pending',
    );
  }
}
