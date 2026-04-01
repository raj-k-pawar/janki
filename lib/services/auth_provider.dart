import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? '';

  final DatabaseService _db = DatabaseService();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final token = prefs.getString('auth_token');
    if (userData != null && token != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      _db.setToken(token);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _db.login(username, password);
      if (result['success'] == true) {
        _user = UserModel.fromJson(result['user']);
        final token = result['token'] ?? '';
        _db.setToken(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        await prefs.setString('auth_token', token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String role,
    required String mobile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _db.register(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        mobile: mobile,
      );
      _isLoading = false;
      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _db.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
