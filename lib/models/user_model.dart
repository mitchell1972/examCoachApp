class UserModel {
  String? phoneNumber;
  String? otpCode;
  String? examType;
  String? subject;
  String status;
  DateTime? trialEndTime;

  UserModel({
    this.phoneNumber,
    this.otpCode,
    this.examType,
    this.subject,
    this.status = 'trial',
    this.trialEndTime,
  });

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
      'phoneNumber': phoneNumber,
      'otpCode': otpCode,
      'examType': examType,
      'subject': subject,
      'status': status,
      'trialEndTime': trialEndTime?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phoneNumber: json['phoneNumber'],
      otpCode: json['otpCode'],
      examType: json['examType'],
      subject: json['subject'],
      status: json['status'] ?? 'trial',
      trialEndTime: json['trialEndTime'] != null 
          ? DateTime.parse(json['trialEndTime'])
          : null,
    );
  }
} 