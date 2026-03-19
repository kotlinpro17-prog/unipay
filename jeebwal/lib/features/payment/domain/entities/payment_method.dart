import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final bool isActive;
  final String licenseStatus;
  final String statusMessage;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.isActive = true,
    this.licenseStatus = 'ACTIVE',
    this.statusMessage = '',
  });

  @override
  List<Object?> get props => [id, name, logoUrl, isActive, licenseStatus, statusMessage];
}
