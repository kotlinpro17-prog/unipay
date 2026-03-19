import '../../domain/entities/fees_data.dart';

class FeesDataModel extends FeesData {
  const FeesDataModel({
    required super.tuitionFees,
    required super.examFees,
    required super.registrationFees,
    required super.otherFees,
    required super.semesterFees,
    required super.materialFees,
    required super.fines,
    required super.total,
    required super.paid,
    required super.remaining,
  });

  factory FeesDataModel.fromJson(Map<String, dynamic> json) {
    return FeesDataModel(
      tuitionFees: (json['tuitionFees'] as num?)?.toDouble() ?? 0.0,
      examFees: (json['examFees'] as num?)?.toDouble() ?? 0.0,
      registrationFees: (json['registrationFees'] as num?)?.toDouble() ?? 0.0,
      otherFees: (json['otherFees'] as num?)?.toDouble() ?? 0.0,
      semesterFees: (json['semesterFees'] as num?)?.toDouble() ?? 0.0,
      materialFees: (json['materialFees'] as num?)?.toDouble() ?? 0.0,
      fines: (json['fines'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
