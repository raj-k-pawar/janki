import 'dart:convert';
import 'package:http/http.dart' as http;

// *** UPDATE THIS URL after deploying api.php to your hosting ***
const String kBaseUrl = 'https://yourdomain.infinityfreeapp.com/api.php';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String _todayStr() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      final body = <String, dynamic>{'action': action};
      body.addAll(data);
      final response = await http
          .post(
            Uri.parse(kBaseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Server error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) {
    return _post('login', {'username': username, 'password': password});
  }

  Future<Map<String, dynamic>> getDashboardStats(String date) {
    return _post('getDashboardStats', {'date': date});
  }

  Future<Map<String, dynamic>> getBookings({String? date}) {
    return _post('getBookings', {'date': date ?? _todayStr()});
  }

  Future<Map<String, dynamic>> getAllBookings() {
    return _post('getAllBookings', {});
  }

  Future<Map<String, dynamic>> addBooking(Map<String, dynamic> booking) {
    return _post('addBooking', booking);
  }

  Future<Map<String, dynamic>> updateBooking(
    int id,
    Map<String, dynamic> booking,
  ) {
    final data = <String, dynamic>{'id': id};
    data.addAll(booking);
    return _post('updateBooking', data);
  }

  Future<Map<String, dynamic>> deleteBooking(int id) {
    return _post('deleteBooking', {'id': id});
  }

  Future<Map<String, dynamic>> getWorkers() {
    return _post('getWorkers', {});
  }

  Future<Map<String, dynamic>> addWorker(Map<String, dynamic> worker) {
    return _post('addWorker', worker);
  }

  Future<Map<String, dynamic>> updateWorker(
    int id,
    Map<String, dynamic> worker,
  ) {
    final data = <String, dynamic>{'id': id};
    data.addAll(worker);
    return _post('updateWorker', data);
  }

  Future<Map<String, dynamic>> deleteWorker(int id) {
    return _post('deleteWorker', {'id': id});
  }
}
