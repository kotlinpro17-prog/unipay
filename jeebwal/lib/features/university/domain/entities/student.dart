import 'package:equatable/equatable.dart';

class Fee extends Equatable {
  final int id;
  final String description;
  final double amount;
  final int year;
  final int semester;
  final String dueDate;
  final bool isPaid;

  const Fee({
    required this.id,
    required this.description,
    required this.amount,
    required this.year,
    required this.semester,
    required this.dueDate,
    required this.isPaid,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    year,
    semester,
    dueDate,
    isPaid,
  ];
}

class Student extends Equatable {
  final String? universityId;
  final String payableId;
  final int universityDbId;
  final String studentName;
  final String universityName;
  final String majorName;
  final String collegeName;
  final int currentYear;
  final int currentSemester;
  final String status;
  final double balance;
  final List<Fee> unpaidFees;
  final List<Map<String, dynamic>> availableWallets;

  const Student({
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
    required this.availableWallets,
  });

  @override
  List<Object?> get props => [
    universityId,
    payableId,
    universityDbId,
    studentName,
    universityName,
    majorName,
    collegeName,
    currentYear,
    currentSemester,
    status,
    balance,
    unpaidFees,
    availableWallets,
  ];
}
