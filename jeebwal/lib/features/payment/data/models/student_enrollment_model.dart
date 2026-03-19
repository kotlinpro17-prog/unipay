class StudentEnrollmentModel {
  final String? universityId;
  final String payableId;
  final String studentName;
  final String universityName;
  final String majorName;
  final String collegeName;
  final int currentYear;
  final int currentSemester;
  final String status;
  final double balance;
  final List<UnpaidFeeModel> unpaidFees;

  final int universityDbId;

  StudentEnrollmentModel({
    this.universityId,
    required this.payableId,
    required this.universityDbId,
    required this.studentName,
    required this.universityName,
    required this.majorName,
    required this.collegeName,
    required this.currentYear,
    required this.currentSemester,
    required this.status,
    required this.balance,
    required this.unpaidFees,
  });

  factory StudentEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return StudentEnrollmentModel(
      universityId: json['university_id']?.toString(),
      payableId:
          json['payable_id']?.toString() ??
          json['university_id']?.toString() ??
          '',
      universityDbId: json['university_db_id'] ?? 0,
      studentName: json['student_name'] ?? '',
      universityName: json['university_name'] ?? '',
      majorName: json['major_name'] ?? '',
      collegeName: json['college_name'] ?? '',
      currentYear: json['current_year'] ?? 1,
      currentSemester: json['current_semester'] ?? 1,
      status: json['status'] ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      unpaidFees:
          (json['unpaid_fees'] as List?)
              ?.map((i) => UnpaidFeeModel.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'university_id': universityId,
      'payable_id': payableId,
      'university_db_id': universityDbId,
      'student_name': studentName,
      'university_name': universityName,
      'major_name': majorName,
      'college_name': collegeName,
      'current_year': currentYear,
      'current_semester': currentSemester,
      'status': status,
      'balance': balance,
      'unpaid_fees': unpaidFees.map((i) => i.toJson()).toList(),
    };
  }
}

class UnpaidFeeModel {
  final int id;
  final String description;
  final double amount;
  final int year;
  final int semester;
  final String dueDate;
  final bool isPaid;

  UnpaidFeeModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.year,
    required this.semester,
    required this.dueDate,
    required this.isPaid,
  });

  factory UnpaidFeeModel.fromJson(Map<String, dynamic> json) {
    return UnpaidFeeModel(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      year: json['year'] ?? 1,
      semester: json['semester'] ?? 1,
      dueDate: json['due_date'] ?? '',
      isPaid: json['is_paid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'year': year,
      'semester': semester,
      'due_date': dueDate,
      'is_paid': isPaid,
    };
  }
}
