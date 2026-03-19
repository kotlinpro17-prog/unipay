import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/payment_method_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/student_enrollment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<StudentEnrollmentModel> getStudentDetails(String studentId);
  Future<Map<String, dynamic>> loginToWallet({
    required String phoneNumber,
    required String password,
  });
  Future<Map<String, dynamic>> payUniversity({
    required String studentUniversityId,
    required double amount,
    required int universityId,
    String? description,
    String? token, // Support passing the wallet token
    String? universityWalletAcc,
  });
  Future<Map<String, dynamic>> getWalletBalance(String token);
  Future<List<PaymentTransactionModel>> getPaymentHistory();
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final response = await apiClient.get('/wallet/payment-methods/');
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['status'] == 'success') {
      final List list = responseData['data'];
      return list.map((e) => PaymentMethodModel.fromJson(e)).toList();
    } else {
      throw Exception(
        responseData['message'] ?? 'Failed to load payment methods',
      );
    }
  }

  @override
  Future<StudentEnrollmentModel> getStudentDetails(String studentId) async {
    final response = await apiClient.get('/wallet/student-details/$studentId/');
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return StudentEnrollmentModel.fromJson(responseData);
    } else {
      throw Exception(responseData['error'] ?? 'فشل الحصول على بيانات الطالب');
    }
  }

  @override
  Future<Map<String, dynamic>> loginToWallet({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/wallet/login/',
      data: {'phoneNumber': phoneNumber, 'password': password},
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return responseData['data'];
    } else {
      throw Exception(
        responseData['message'] ?? 'فشل تسجيل الدخول إلى المحفظة',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> payUniversity({
    required String studentUniversityId,
    required double amount,
    required int universityId,
    String? description,
    String? token,
    String? universityWalletAcc,
  }) async {
    final response = await apiClient.post(
      '/wallet/pay-university/',
      token: token,
      data: {
        'student_university_id': studentUniversityId,
        'amount': amount,
        'university_id': universityId,
        'description': description ?? 'University Fee Payment',
        if (universityWalletAcc != null) 'university_wallet_acc': universityWalletAcc,
      },
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل عملية السداد');
    }
  }

  @override
  Future<Map<String, dynamic>> getWalletBalance(String token) async {
    final response = await apiClient.get('/wallet/balance/', token: token);

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? 'فشل الحصول على رصيد المحفظة');
    }
  }

  @override
  Future<List<PaymentTransactionModel>> getPaymentHistory() async {
    final response = await apiClient.get(
      '/wallet/history/',
    ); // Assuming history endpoint exists in bank system
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => PaymentTransactionModel.fromJson(e)).toList();
    }
    return [];
  }
}
