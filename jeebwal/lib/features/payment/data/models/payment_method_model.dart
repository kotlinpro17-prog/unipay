import '../../domain/entities/payment_method.dart';
import '../../../../core/network/api_client.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.isActive,
    required super.licenseStatus,
    required super.statusMessage,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    String logo = json['logoUrl'] ?? '';
    // If it's a relative path from settlement system (8001)
    if (logo.isNotEmpty && !logo.startsWith('http')) {
      logo = 'http://${ApiClient.serverIp}:8001$logo';
    }

    return PaymentMethodModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Wallet',
      logoUrl: logo,
      isActive: json['is_active'] ?? true,
      licenseStatus: json['license_status'] ?? 'ACTIVE',
      statusMessage: json['status_message'] ?? '',
    );
  }
}
