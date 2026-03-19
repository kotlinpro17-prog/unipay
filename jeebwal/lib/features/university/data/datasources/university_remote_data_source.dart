import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/university_model.dart';
import '../models/student_model.dart';

abstract class UniversityRemoteDataSource {
  Future<List<UniversityModel>> getUniversities();
  Future<bool> linkAccount({
    required String universityId,
    required String academicId,
    required String password,
  });
  Future<Map<String, dynamic>> getFees();
  Future<StudentModel> getStudentDetails(String universityId, {String? searchType});
}

class UniversityRemoteDataSourceImpl implements UniversityRemoteDataSource {
  final ApiClient apiClient;

  UniversityRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<StudentModel> getStudentDetails(String universityId, {String? searchType}) async {
    String url = '/wallet/student-details/$universityId/';
    if (searchType != null && searchType.isNotEmpty) {
      url += '?search_type=$searchType';
    }
    
    final response = await apiClient.get(url);
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return StudentModel.fromJson(responseData);
    } else {
      throw Exception(
        responseData['error'] ?? 'Failed to load student details',
      );
    }
  }

  @override
  Future<List<UniversityModel>> getUniversities() async {
    try {
      final response = await apiClient.get('/wallet/universities/');
      final responseData = jsonDecode(response.body);

      print('DEBUG: Universities Response Status: ${response.statusCode}');
      print('DEBUG: Universities Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List? list;
        if (responseData is Map && responseData['status'] == 'success') {
          list = responseData['data'];
        } else if (responseData is List) {
          list = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          list = responseData['data'];
        }

        if (list != null) {
          print(
            'DEBUG: RemoteDataSource - Mapping ${list.length} items to UniversityModel',
          );
          return list.map((e) {
            try {
              return UniversityModel.fromJson(e as Map<String, dynamic>);
            } catch (err) {
              print(
                'DEBUG: RemoteDataSource - Item mapping failed: $err for record: $e',
              );
              rethrow;
            }
          }).toList();
        }
      }

      String message = 'Failed to load universities';
      if (responseData is Map && responseData.containsKey('message')) {
        message = responseData['message'];
      }
      throw Exception(message);
    } catch (e) {
      print('DEBUG: Error in getUniversities: $e');
      rethrow;
    }
  }

  @override
  Future<bool> linkAccount({
    required String universityId,
    required String academicId,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/universities/link/',
      data: {
        'universityId': universityId,
        'academicId': academicId,
        'password': password,
      },
    );

    final responseData = jsonDecode(response.body);
    return response.statusCode == 200 && responseData['status'] == 'success';
  }

  @override
  Future<Map<String, dynamic>> getFees() async {
    final response = await apiClient.get('/student/fees/');
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return responseData['data'];
    } else {
      throw Exception(responseData['message'] ?? 'Failed to load fees');
    }
  }
}
