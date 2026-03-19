// import 'dart:convert';
// import '../../../../core/network/api_client.dart';
// import '../models/user_model.dart';

// abstract class AuthRemoteDataSource {
//   Future<UserModel> login(String phoneNumber, String password);
//   Future<UserModel> signUp(
//     String fullName,
//     String phoneNumber,
//     String password,
//     String? email,
//   );
// }

// class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
//   final ApiClient apiClient;

//   AuthRemoteDataSourceImpl({required this.apiClient});

//   @override
//   Future<UserModel> login(String phoneNumber, String password) async {
//     final response = await apiClient.post(
//       '/wallet/login/',
//       data: {'phoneNumber': phoneNumber, 'password': password},
//     );

//     final responseData = jsonDecode(response.body);

//     if (response.statusCode == 200 && responseData['status'] == 'success') {
//       return UserModel.fromJson(responseData['data']);
//     } else {
//       throw Exception(responseData['message'] ?? 'Login failed');
//     }
//   }

//   @override
//   Future<UserModel> signUp(
//     String fullName,
//     String phoneNumber,
//     String password,
//     String? email,
//   ) async {
//     final response = await apiClient.post(
//       '/wallet/signup/',
//       data: {
//         'fullName': fullName,
//         'phoneNumber': phoneNumber,
//         'password': password,
//         'email': email,
//       },
//     );

//     final responseData = jsonDecode(response.body);

//     if (response.statusCode == 200 && responseData['status'] == 'success') {
//       return UserModel.fromJson(responseData['data']);
//     } else {
//       throw Exception(responseData['message'] ?? 'Sign up failed');
//     }
//   }
// }
