import 'dart:math';
import '../../../../core/database/database_helper.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> login(String phoneNumber, String password);
  Future<UserModel> signUp(
    String fullName,
    String phoneNumber,
    String password,
    String? email,
    String? profilePicture,
  );
  Future<UserModel?> getUserByPhone(String phoneNumber);
  Future<UserModel> updateProfile(UserModel user);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper databaseHelper;

  AuthLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<UserModel> login(String phoneNumber, String password) async {
    final userData = await databaseHelper.getUser(phoneNumber, password);
    if (userData != null) {
      return UserModel.fromJson(userData);
    } else {
      throw Exception('Invalid phone number or password');
    }
  }

  @override
  Future<UserModel> signUp(
    String fullName,
    String phoneNumber,
    String password,
    String? email,
    String? profilePicture,
  ) async {
    // Check if user already exists
    final existingUser = await databaseHelper.getUserByPhone(phoneNumber);
    if (existingUser != null) {
      throw Exception('user_already_exists');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final token = _generateRandomToken();

    final userData = {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePicture': profilePicture,
      'password': password,
      'token': token,
    };

    await databaseHelper.insertUser(userData);
    return UserModel.fromJson(userData);
  }

  @override
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    final userData = await databaseHelper.getUserByPhone(phoneNumber);
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final userData = {
      'id': user.id,
      'fullName': user.fullName,
      'phoneNumber': user.phoneNumber,
      'email': user.email,
      'profilePicture': user.profilePicture,
      'token': user.token,
    };
    await databaseHelper.updateUser(userData);
    return user;
  }

  String _generateRandomToken() {
    var random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
