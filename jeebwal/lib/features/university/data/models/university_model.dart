import '../../domain/entities/university.dart';
import '../../../../core/network/api_client.dart';

class UniversityModel extends University {
  const UniversityModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.governorate,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    String logo = json['logo']?.toString() ?? '';

    // If logo is a relative path, prepend the base URL from ApiClient
    if (logo.isNotEmpty && !logo.startsWith('http')) {
      logo = '${ApiClient.logoBaseUrl}$logo';
    }

    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Unknown University';
    final governorate = json['governorate']?.toString() ?? 'N/A';

    return UniversityModel(
      id: id,
      name: name,
      logoUrl: logo,
      governorate: governorate,
    );
  }
}
