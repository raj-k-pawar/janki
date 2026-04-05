import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static StorageService? _i;
  static StorageService get instance => _i ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get prefs async => _prefs ??= await SharedPreferences.getInstance();

  // ── helpers ──
  Future<List<Map<String,dynamic>>> _getList(String key) async {
    final p = await prefs;
    final s = p.getString(key);
    if (s == null) return [];
    return List<Map<String,dynamic>>.from(jsonDecode(s));
  }
  Future<void> _setList(String key, List<Map<String,dynamic>> list) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(list));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const _usersKey     = 'users_v1';
  static const _sessionKey   = 'session_user';

  Future<void> _seedUsers() async {
    final list = await _getList(_usersKey);
    if (list.isNotEmpty) return;
    final seeds = [
      UserModel(id:'u1', username:'manager1', fullName:'Rajesh Patel',   phone:'9876543210', role:UserRole.manager),
      UserModel(id:'u2', username:'manager2', fullName:'Suresh Kumar',   phone:'9876543211', role:UserRole.manager),
      UserModel(id:'u3', username:'owner1',   fullName:'Janki Devi',     phone:'9876543212', role:UserRole.owner),
      UserModel(id:'u4', username:'admin1',   fullName:'Admin User',     phone:'9876543213', role:UserRole.admin),
      UserModel(id:'u5', username:'canteen1', fullName:'Ramesh Singh',   phone:'9876543214', role:UserRole.canteen),
    ];
    // store with password
    final withPass = [
      {...seeds[0].toJson(), 'password':'manager123'},
      {...seeds[1].toJson(), 'password':'manager456'},
      {...seeds[2].toJson(), 'password':'owner123'},
      {...seeds[3].toJson(), 'password':'admin123'},
      {...seeds[4].toJson(), 'password':'canteen123'},
    ];
    await _setList(_usersKey, withPass);
  }

  Future<UserModel?> login(String username, String password) async {
    await _seedUsers();
    await _seedPackages();
    final list = await _getList(_usersKey);
    for (final u in list) {
      if (u['username'] == username && u['password'] == password) {
        final user = UserModel.fromJson(u);
        final p = await prefs;
        await p.setString(_sessionKey, jsonEncode(u));
        return user;
      }
    }
    return null;
  }


  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    await _seedUsers();
    final list = await _getList(_usersKey);
    for (final u in list) {
      if (u['username'] == username) return false;
    }
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'username': username,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
    };
    list.add(newUser);
    await _setList(_usersKey, list);
    return true;
  }

  Future<UserModel?> getSession() async {
    final p = await prefs;
    final s = p.getString(_sessionKey);
    if (s == null) return null;
    return UserModel.fromJson(jsonDecode(s));
  }

  Future<void> logout() async {
    final p = await prefs;
    await p.remove(_sessionKey);
  }

  Future<List<UserModel>> getAllManagers() async {
    await _seedUsers();
    final list = await _getList(_usersKey);
    return list.where((u) => u['role'] == 'manager')
        .map((u) => UserModel.fromJson(u)).toList();
  }

  // ── Packages ──────────────────────────────────────────────────────────────
  static const _packagesKey = 'packages_v1';

  Future<void> _seedPackages() async {
    final list = await _getList(_packagesKey);
    if (list.isNotEmpty) return;
    final seeds = [
      PackageModel(id:'p1', name:'सकाळी हाफ डे पॅकेज 🌅',
          timeSlot:'सकाळी 10:00 ते दुपारी 03:00',
          breakfast:true, lunch:true, snacks:false, dinner:false,
          adultPrice:500, childPrice:400, isStay:false),
      PackageModel(id:'p2', name:'सायंकाळी हाफ डे पॅकेज 🌅',
          timeSlot:'दुपारी 03:00 ते सायंकाळी 08:00',
          breakfast:false, lunch:false, snacks:true, dinner:true,
          adultPrice:500, childPrice:400, isStay:false),
      PackageModel(id:'p3', name:'🌟 फुल डे पॅकेज 🌟',
          timeSlot:'सकाळी 10:00 ते सायंकाळी 06:00',
          breakfast:true, lunch:true, snacks:false, dinner:false,
          adultPrice:650, childPrice:500, isStay:false),
      PackageModel(id:'p4', name:'निवासी AC डिलक्स रूम (सकाळी)',
          timeSlot:'सकाळी 10:00 ते दुसऱ्या दिवशी 09:30',
          breakfast:true, lunch:true, snacks:true, dinner:true,
          adultPrice:1800, childPrice:1300, isStay:true),
      PackageModel(id:'p5', name:'निवासी AC डिलक्स रूम (दुपारी)',
          timeSlot:'दुपारी 03:00 ते दुसऱ्या दिवशी 02:30',
          breakfast:true, lunch:true, snacks:true, dinner:true,
          adultPrice:1800, childPrice:1300, isStay:true),
      PackageModel(id:'p6', name:'🏠 निवासी Non AC रूम (सकाळी) 🌿',
          timeSlot:'सकाळी 10:00 ते दुसऱ्या दिवशी 09:30',
          breakfast:true, lunch:true, snacks:true, dinner:true,
          adultPrice:1500, childPrice:1100, isStay:true),
      PackageModel(id:'p7', name:'🏠 निवासी Non AC रूम (दुपारी) 🌿',
          timeSlot:'दुपारी 03:00 ते दुसऱ्या दिवशी 02:30',
          breakfast:true, lunch:true, snacks:true, dinner:true,
          adultPrice:1500, childPrice:1100, isStay:true),
    ];
    await _setList(_packagesKey, seeds.map((p) => p.toJson()).toList());
  }

  Future<List<PackageModel>> getPackages() async {
    await _seedPackages();
    final list = await _getList(_packagesKey);
    return list.map((p) => PackageModel.fromJson(p)).toList();
  }

  Future<void> savePackage(PackageModel pkg) async {
    final list = await _getList(_packagesKey);
    final idx = list.indexWhere((p) => p['id'] == pkg.id);
    if (idx >= 0) list[idx] = pkg.toJson(); else list.add(pkg.toJson());
    await _setList(_packagesKey, list);
  }

  Future<void> deletePackage(String id) async {
    final list = await _getList(_packagesKey);
    list.removeWhere((p) => p['id'] == id);
    await _setList(_packagesKey, list);
  }

  // ── Customers ─────────────────────────────────────────────────────────────
  static const _customersKey = 'customers_v2';

  Future<List<CustomerModel>> getCustomers() async {
    final list = await _getList(_customersKey);
    return list.map((c) => CustomerModel.fromJson(c)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<CustomerModel>> getCustomersByDate(DateTime date) async {
    final all = await getCustomers();
    return all.where((c) =>
      c.visitDate.year == date.year &&
      c.visitDate.month == date.month &&
      c.visitDate.day == date.day).toList();
  }

  Future<void> saveCustomer(CustomerModel c) async {
    final list = await _getList(_customersKey);
    final idx = list.indexWhere((e) => e['id'] == c.id);
    if (idx >= 0) list[idx] = c.toJson(); else list.insert(0, c.toJson());
    await _setList(_customersKey, list);
  }

  Future<void> deleteCustomer(String id) async {
    final list = await _getList(_customersKey);
    list.removeWhere((c) => c['id'] == id);
    await _setList(_customersKey, list);
  }

  Future<void> markQrUsed(String customerId) async {
    final list = await _getList(_customersKey);
    final idx = list.indexWhere((c) => c['id'] == customerId);
    if (idx >= 0) list[idx]['qrUsed'] = true;
    await _setList(_customersKey, list);
  }

  // ── Workers ───────────────────────────────────────────────────────────────
  static const _workersKey = 'workers_v2';

  Future<List<WorkerModel>> getWorkers() async {
    final list = await _getList(_workersKey);
    return list.map((w) => WorkerModel.fromJson(w)).toList();
  }

  Future<void> saveWorker(WorkerModel w) async {
    final list = await _getList(_workersKey);
    final idx = list.indexWhere((e) => e['id'] == w.id);
    if (idx >= 0) list[idx] = w.toJson(); else list.add(w.toJson());
    await _setList(_workersKey, list);
  }

  Future<void> deleteWorker(String id) async {
    final list = await _getList(_workersKey);
    list.removeWhere((w) => w['id'] == id);
    await _setList(_workersKey, list);
  }

  // ── Attendance ────────────────────────────────────────────────────────────
  static const _attendanceKey = 'attendance_v1';

  Future<List<AttendanceRecord>> getAttendance() async {
    final list = await _getList(_attendanceKey);
    return list.map((a) => AttendanceRecord.fromJson(a)).toList();
  }

  Future<void> setAttendance(String workerId, DateTime date, bool present) async {
    final list = await _getList(_attendanceKey);
    final dateStr = '${date.year}-${date.month}-${date.day}';
    list.removeWhere((a) {
      final d = DateTime.parse(a['date']);
      return a['workerId'] == workerId &&
          '${d.year}-${d.month}-${d.day}' == dateStr;
    });
    list.add(AttendanceRecord(workerId: workerId, date: date, present: present).toJson());
    await _setList(_attendanceKey, list);
  }

  Future<bool> getWorkerAttendance(String workerId, DateTime date) async {
    final all = await getAttendance();
    final dateStr = '${date.year}-${date.month}-${date.day}';
    final rec = all.where((a) {
      final d = a.date;
      return a.workerId == workerId && '${d.year}-${d.month}-${d.day}' == dateStr;
    });
    if (rec.isEmpty) return false;
    return rec.first.present;
  }

  // ── Advance Payments ──────────────────────────────────────────────────────
  static const _advanceKey = 'advances_v1';

  Future<List<AdvancePayment>> getAdvances() async {
    final list = await _getList(_advanceKey);
    return list.map((a) => AdvancePayment.fromJson(a)).toList();
  }

  Future<void> addAdvance(AdvancePayment a) async {
    final list = await _getList(_advanceKey);
    list.add(a.toJson());
    await _setList(_advanceKey, list);
  }

  // ── Salary Payments ───────────────────────────────────────────────────────
  static const _salaryKey = 'salaries_v1';

  Future<List<SalaryPayment>> getSalaries() async {
    final list = await _getList(_salaryKey);
    return list.map((s) => SalaryPayment.fromJson(s)).toList();
  }

  Future<void> addSalary(SalaryPayment s) async {
    final list = await _getList(_salaryKey);
    list.add(s.toJson());
    await _setList(_salaryKey, list);
  }

  // ── Enquiries ─────────────────────────────────────────────────────────────
  static const _enquiryKey = 'enquiries_v1';

  Future<List<EnquiryModel>> getEnquiries() async {
    final list = await _getList(_enquiryKey);
    return list.map((e) => EnquiryModel.fromJson(e)).toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<EnquiryModel>> getEnquiriesByDate(DateTime date) async {
    final all = await getEnquiries();
    return all.where((e) =>
        e.date.year==date.year && e.date.month==date.month && e.date.day==date.day).toList();
  }

  Future<void> addEnquiry(EnquiryModel e) async {
    final list = await _getList(_enquiryKey);
    list.insert(0, e.toJson());
    await _setList(_enquiryKey, list);
  }
}
