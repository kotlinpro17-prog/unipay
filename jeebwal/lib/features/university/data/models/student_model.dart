import 'package:jeebwal/features/university/domain/entities/student.dart';

class FeeModel extends Fee {
  const FeeModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.year,
    required super.semester,
    required super.dueDate,
    required super.isPaid,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      id: json['id'],
      description: json['description'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      year: json['year'],
      semester: json['semester'],
      dueDate: json['due_date'] ?? '',
      isPaid: json['is_paid'] ?? false,
    );
  }
}

class StudentModel extends Student {
  const StudentModel({
    super.universityId,
    required super.payableId,
    required super.universityDbId,
    required super.studentName,
    required super.universityName,
    required super.majorName,
    required super.collegeName,
    required super.currentYear,
    required super.currentSemester,
    required super.status,
    required super.balance,
    required super.unpaidFees,
    required super.availableWallets,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      universityId: json['university_id']?.toString(),
      payableId:
          json['payable_id']?.toString() ??
          json['university_id']?.toString() ??
          '',
      universityDbId: (json['university_db_id'] is int)
          ? json['university_db_id']
          : int.tryParse(json['university_db_id']?.toString() ?? '0') ?? 0,
      studentName: json['student_name'] ?? '',
      universityName: json['university_name'] ?? '',
      majorName: json['major_name'] ?? '',
      collegeName: json['college_name'] ?? '',
      currentYear: json['current_year'] ?? 1,
      currentSemester: json['current_semester'] ?? 1,
      status: json['status'] ?? 'PENDING',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      unpaidFees:
          (json['unpaid_fees'] as List?)
              ?.map((e) => FeeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableWallets: (json['available_wallets'] as List?)
          ?.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return {
              'provider_name': map['provider_name'],
              'account_number': map['account_number'],
              'is_active': map['is_active'] ?? true, // Default to true if old API
              'status_message': map['status_message'] ?? '',
            };
          })
          .toList() ?? [],
    );
  }
}
