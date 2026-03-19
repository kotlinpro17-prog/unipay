import 'package:equatable/equatable.dart';

class StudentData extends Equatable {
  final String fullName;
  final String academicId;
  final String major;
  final String level;
  final double totalFees;
  final double paidFees;
  final double remainingFees;

  const StudentData({
    required this.fullName,
    required this.academicId,
    required this.major,
    required this.level,
    required this.totalFees,
    required this.paidFees,
    required this.remainingFees,
  });

  @override
  List<Object?> get props => [
    fullName,
    academicId,
    major,
    level,
    totalFees,
    paidFees,
    remainingFees,
  ];
}
