import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: MySQL cannot be accessed directly from Flutter. You MUST have a PHP
// REST API layer on your server (InfinityFree hosting). 
// Create a folder 'api' on your InfinityFree hosting and upload the PHP files
// provided in the 'php_api/' folder of this project.
// Then update BASE_URL below to your actual domain.
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseService {
  // TODO: Replace with your actual InfinityFree domain
  static const String BASE_URL = 'https://yourdomain.infinityfreeapp.com/api';

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  String? _authToken;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/login.php'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String role,
    required String mobile,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/register.php'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'full_name': fullName,
        'role': role,
        'mobile': mobile,
      }),
    );
    return _parse(res);
  }

  // ── DASHBOARD ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$BASE_URL/dashboard.php'),
      headers: _headers,
    );
    return _parse(res);
  }

  // ── CUSTOMERS ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCustomers() async {
    final res = await http.get(
      Uri.parse('$BASE_URL/customers.php'),
      headers: _headers,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> addCustomer(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/customers.php'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> updateCustomer(
      int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$BASE_URL/customers.php?id=$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> deleteCustomer(int id) async {
    final res = await http.delete(
      Uri.parse('$BASE_URL/customers.php?id=$id'),
      headers: _headers,
    );
    return _parse(res);
  }

  // ── WORKERS ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWorkers() async {
    final res = await http.get(
      Uri.parse('$BASE_URL/workers.php'),
      headers: _headers,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> addWorker(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/workers.php'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> updateWorker(
      int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$BASE_URL/workers.php?id=$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> deleteWorker(int id) async {
    final res = await http.delete(
      Uri.parse('$BASE_URL/workers.php?id=$id'),
      headers: _headers,
    );
    return _parse(res);
  }

  // ── QR ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> validateQR(String qrToken) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/validate_qr.php'),
      headers: _headers,
      body: jsonEncode({'qr_token': qrToken}),
    );
    return _parse(res);
  }

  // ── HELPER ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _parse(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }
  }
}
