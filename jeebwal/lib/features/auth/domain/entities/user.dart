import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? profilePicture;
  final String token;

  const User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.profilePicture,
    required this.token,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    phoneNumber,
    email,
    profilePicture,
    token,
  ];
}
