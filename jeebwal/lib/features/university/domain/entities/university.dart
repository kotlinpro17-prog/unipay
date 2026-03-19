import 'package:equatable/equatable.dart';

class University extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String governorate;

  const University({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.governorate,
  });

  @override
  List<Object> get props => [id, name, logoUrl, governorate];
}
