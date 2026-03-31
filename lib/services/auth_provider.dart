import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(decoded);
        notifyListeners();
      }
    } catch (_) {
      // ignore errors on auto-login
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService().login(username, password);
    _isLoading = false;

    if (result['success'] == true) {
      final userMap = result['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(userMap);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(userMap));
      notifyListeners();
      return true;
    }

    _error = result['message']?.toString() ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }
}
