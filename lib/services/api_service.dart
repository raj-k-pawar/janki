import 'dart:convert';
import 'package:http/http.dart' as http;

// ⚠️ Deploy api.php to your InfinityFree hosting and update this URL
const String BASE_URL = 'https://yourdomain.infinityfreeapp.com/api.php';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> _post(String action, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse(BASE_URL),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': action, ...data}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) =>
      _post('login', {'username': username, 'password': password});

  Future<Map<String, dynamic>> getDashboardStats(String date) =>
      _post('getDashboardStats', {'date': date});

  Future<Map<String, dynamic>> getBookings({String? date}) =>
      _post('getBookings', {'date': date ?? _today()});

  Future<Map<String, dynamic>> getAllBookings() => _post('getAllBookings', {});

  Future<Map<String, dynamic>> addBooking(Map<String, dynamic> b) =>
      _post('addBooking', b);

  Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> b) =>
      _post('updateBooking', {'id': id, ...b});

  Future<Map<String, dynamic>> deleteBooking(int id) =>
      _post('deleteBooking', {'id': id});

  Future<Map<String, dynamic>> getWorkers() => _post('getWorkers', {});

  Future<Map<String, dynamic>> addWorker(Map<String, dynamic> w) =>
      _post('addWorker', w);

  Future<Map<String, dynamic>> updateWorker(int id, Map<String, dynamic> w) =>
      _post('updateWorker', {'id': id, ...w});

  Future<Map<String, dynamic>> deleteWorker(int id) =>
      _post('deleteWorker', {'id': id});

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
