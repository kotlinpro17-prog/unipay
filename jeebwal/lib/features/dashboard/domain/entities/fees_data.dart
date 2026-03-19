import 'package:equatable/equatable.dart';

class FeesData extends Equatable {
  final double tuitionFees;
  final double examFees;
  final double registrationFees;
  final double otherFees;
  final double semesterFees;
  final double materialFees;
  final double fines;
  final double total;
  final double paid;
  final double remaining;

  const FeesData({
    required this.tuitionFees,
    required this.examFees,
    required this.registrationFees,
    required this.otherFees,
    required this.semesterFees,
    required this.materialFees,
    required this.fines,
    required this.total,
    required this.paid,
    required this.remaining,
  });

  @override
  List<Object?> get props => [
    tuitionFees,
    examFees,
    registrationFees,
    otherFees,
    semesterFees,
    materialFees,
    fines,
    total,
    paid,
    remaining,
  ];
}
