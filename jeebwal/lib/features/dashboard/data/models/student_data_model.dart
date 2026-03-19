import '../../domain/entities/student_data.dart';

class StudentDataModel extends StudentData {
  const StudentDataModel({
    required super.fullName,
    required super.academicId,
    required super.major,
    required super.level,
    required super.totalFees,
    required super.paidFees,
    required super.remainingFees,
  });

  factory StudentDataModel.fromJson(Map<String, dynamic> json) {
    return StudentDataModel(
      fullName: json['fullName'],
      academicId: json['academicId'],
      major: json['major'],
      level: json['level'],
      totalFees: (json['totalFees'] as num).toDouble(),
      paidFees: (json['paidFees'] as num).toDouble(),
      remainingFees: (json['remainingFees'] as num).toDouble(),
    );
  }
}
