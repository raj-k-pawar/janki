// lib/services/api_service.dart
// Since Flutter cannot connect directly to MySQL, we use an HTTP API layer.
// You need to deploy the companion PHP API (api.php) to your hosting.

import 'dart:convert';
import 'package:http/http.dart' as http;

// ⚠️ IMPORTANT: Deploy api.php to your InfinityFree hosting and update this URL
const String BASE_URL = 'https://janki.infinityfree.me/newapi.php';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> _post(String action, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action, ...data}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // AUTH
  Future<Map<String, dynamic>> login(String username, String password) async {
    return await _post('login', {'username': username, 'password': password});
  }

  // BOOKINGS
  Future<Map<String, dynamic>> getBookings({String? date}) async {
    return await _post('getBookings', {'date': date ?? _today()});
  }

  Future<Map<String, dynamic>> getAllBookings() async {
    return await _post('getAllBookings', {});
  }

  Future<Map<String, dynamic>> addBooking(Map<String, dynamic> booking) async {
    return await _post('addBooking', booking);
  }

  Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> booking) async {
    return await _post('updateBooking', {'id': id, ...booking});
  }

  Future<Map<String, dynamic>> deleteBooking(int id) async {
    return await _post('deleteBooking', {'id': id});
  }

  // DASHBOARD STATS
  Future<Map<String, dynamic>> getDashboardStats(String date) async {
    return await _post('getDashboardStats', {'date': date});
  }

  // WORKERS
  Future<Map<String, dynamic>> getWorkers() async {
    return await _post('getWorkers', {});
  }

  Future<Map<String, dynamic>> addWorker(Map<String, dynamic> worker) async {
    return await _post('addWorker', worker);
  }

  Future<Map<String, dynamic>> updateWorker(int id, Map<String, dynamic> worker) async {
    return await _post('updateWorker', {'id': id, ...worker});
  }

  Future<Map<String, dynamic>> deleteWorker(int id) async {
    return await _post('deleteWorker', {'id': id});
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
