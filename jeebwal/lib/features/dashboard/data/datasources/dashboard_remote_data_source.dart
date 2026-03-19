import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/student_data_model.dart';
import '../models/fees_data_model.dart';

abstract class DashboardRemoteDataSource {
  Future<StudentDataModel> getStudentData();
  Future<FeesDataModel> getFeesDetails();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<StudentDataModel> getStudentData() async {
    final response = await apiClient.get('/student/profile/');
    final responseData = jsonDecode(response.body);
    return StudentDataModel.fromJson(responseData['data']);
  }

  @override
  Future<FeesDataModel> getFeesDetails() async {
    final response = await apiClient.get('/student/fees/');
    final responseData = jsonDecode(response.body);
    return FeesDataModel.fromJson(responseData['data']);
  }
}
