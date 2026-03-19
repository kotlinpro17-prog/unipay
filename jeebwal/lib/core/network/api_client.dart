import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../services/local_storage_service.dart';

class ApiClient {
  // ─── Network Configuration ──────────────────────────────────────────────
  // 127.0.0.1 bekerja dengan 'adb reverse' untuk perangkat fisik (USB)
  // أو 10.0.2.2 للمحاكي (Emulator).
  static const String serverIp = '192.168.0.102';

  // Settlement System (Wallet) – Port 8001
  static String get baseUrl => 'http://$serverIp:8001/api';

  // Student Records System (Universities/Media) – Port 8000
  static String get logoBaseUrl => 'http://$serverIp:8000';

  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders({String? token}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      } else {
        final storage = Get.find<LocalStorageService>();
        final defaultToken = storage.read<String>('token');
        if (defaultToken != null) {
          headers['Authorization'] = 'Token $defaultToken';
        }
      }
    } catch (_) {}
    return headers;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final finalUri = uri.replace(queryParameters: queryParameters);
    final headers = await _getHeaders(token: token);
    print('API GET Request: $finalUri');
    try {
      final response = await _client
          .get(finalUri, headers: headers)
          .timeout(const Duration(seconds: 15));
      print('API Response (${response.statusCode}): ${response.body}');
      return response;
    } catch (e) {
      print('API Error for $finalUri: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String path, {dynamic data, String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(token: token);
    final body = data != null ? jsonEncode(data) : null;
    print('API POST Request: $uri');
    return await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));
  }
}
