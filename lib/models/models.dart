// ─── User ────────────────────────────────────────────────────────────────────
enum UserRole { manager, owner, admin, canteen }

class UserModel {
  final String id, username, fullName, phone;
  final UserRole role;
  UserModel({required this.id, required this.username, required this.fullName,
      required this.phone, required this.role});

  String get roleLabel {
    switch (role) {
      case UserRole.manager: return 'Manager';
      case UserRole.owner:   return 'Owner';
      case UserRole.admin:   return 'Admin';
      case UserRole.canteen: return 'Canteen';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'username': username, 'fullName': fullName,
    'phone': phone, 'role': role.name,
  };
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], username: j['username'], fullName: j['fullName'],
    phone: j['phone'] ?? '',
    role: UserRole.values.firstWhere((r) => r.name == j['role'],
        orElse: () => UserRole.manager),
  );
}

// ─── Package ─────────────────────────────────────────────────────────────────
class PackageModel {
  final String id, name, timeSlot;
  final bool breakfast, lunch, snacks, dinner;
  final double adultPrice, childPrice;
  final bool isStay; // for dashboard stay count

  PackageModel({
    required this.id, required this.name, required this.timeSlot,
    required this.breakfast, required this.lunch,
    required this.snacks, required this.dinner,
    required this.adultPrice, required this.childPrice,
    this.isStay = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'timeSlot': timeSlot,
    'breakfast': breakfast, 'lunch': lunch, 'snacks': snacks, 'dinner': dinner,
    'adultPrice': adultPrice, 'childPrice': childPrice, 'isStay': isStay,
  };
  factory PackageModel.fromJson(Map<String, dynamic> j) => PackageModel(
    id: j['id'], name: j['name'], timeSlot: j['timeSlot'] ?? '',
    breakfast: j['breakfast'] ?? false, lunch: j['lunch'] ?? false,
    snacks: j['snacks'] ?? false, dinner: j['dinner'] ?? false,
    adultPrice: (j['adultPrice'] ?? 0).toDouble(),
    childPrice: (j['childPrice'] ?? 0).toDouble(),
    isStay: j['isStay'] ?? false,
  );

  // isMorning / isEvening for dashboard batch-wise
  bool get isMorning => timeSlot.contains('10:00') && !isStay;
  bool get isEvening  => timeSlot.contains('03:00') && !isStay;
  bool get isFullDay  => timeSlot.contains('06:00') || (timeSlot.contains('10:00') && timeSlot.contains('06:00'));
}

// ─── Food Counts ─────────────────────────────────────────────────────────────
class FoodCounts {
  int breakfast, lunch, snacks, dinner;
  FoodCounts({this.breakfast=0, this.lunch=0, this.snacks=0, this.dinner=0});

  static const breakfastRate = 50.0;
  static const lunchRate     = 100.0;
  static const snacksRate    = 50.0;
  static const dinnerRate    = 100.0;

  double deduction(FoodCounts base) {
    double d = 0;
    d += (base.breakfast - breakfast).clamp(0, 999) * breakfastRate;
    d += (base.lunch     - lunch    ).clamp(0, 999) * lunchRate;
    d += (base.snacks    - snacks   ).clamp(0, 999) * snacksRate;
    d += (base.dinner    - dinner   ).clamp(0, 999) * dinnerRate;
    return d;
  }

  Map<String, dynamic> toJson() => {
    'breakfast': breakfast, 'lunch': lunch, 'snacks': snacks, 'dinner': dinner
  };
  factory FoodCounts.fromJson(Map<String, dynamic> j) => FoodCounts(
    breakfast: j['breakfast']??0, lunch: j['lunch']??0,
    snacks: j['snacks']??0, dinner: j['dinner']??0,
  );
}

// ─── Customer / Booking ──────────────────────────────────────────────────────
enum PaymentMode { cash, online }

class CustomerModel {
  final String id, name, city, phone, packageId, packageName, qrCode, managerId, managerName;
  final int adultsCount, childrenCount;
  final double adultRate, childRate;
  final FoodCounts food;
  final double advance;
  final PaymentMode paymentMode;
  final DateTime visitDate, createdAt;
  final bool qrUsed;

  CustomerModel({
    required this.id, required this.name, required this.city,
    required this.phone, required this.packageId, required this.packageName,
    required this.adultsCount, required this.childrenCount,
    required this.adultRate, required this.childRate,
    required this.food, required this.advance,
    required this.paymentMode, required this.visitDate, required this.createdAt,
    required this.qrCode, required this.managerId, required this.managerName,
    this.qrUsed = false,
  });

  int    get totalGuests => adultsCount + childrenCount;
  double get adultAmount  => adultsCount  * adultRate;
  double get childAmount  => childrenCount * childRate;
  double get baseAmount   => adultAmount + childAmount;

  double get foodDeduction {
    final base = FoodCounts(
      breakfast: food.breakfast,
      lunch: food.lunch,
      snacks: food.snacks,
      dinner: food.dinner,
    );
    return 0; // deduction only when user reduces food below total
  }

  double get totalAmount => baseAmount - advance;

  CustomerModel copyWith({
    String? name, String? city, String? phone, String? packageId, String? packageName,
    int? adultsCount, int? childrenCount, double? adultRate, double? childRate,
    FoodCounts? food, double? advance, PaymentMode? paymentMode,
    DateTime? visitDate, bool? qrUsed,
  }) => CustomerModel(
    id: id, managerId: managerId, managerName: managerName, qrCode: qrCode,
    createdAt: createdAt,
    name: name ?? this.name, city: city ?? this.city, phone: phone ?? this.phone,
    packageId: packageId ?? this.packageId, packageName: packageName ?? this.packageName,
    adultsCount: adultsCount ?? this.adultsCount, childrenCount: childrenCount ?? this.childrenCount,
    adultRate: adultRate ?? this.adultRate, childRate: childRate ?? this.childRate,
    food: food ?? this.food, advance: advance ?? this.advance,
    paymentMode: paymentMode ?? this.paymentMode,
    visitDate: visitDate ?? this.visitDate, qrUsed: qrUsed ?? this.qrUsed,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'city': city, 'phone': phone,
    'packageId': packageId, 'packageName': packageName,
    'adultsCount': adultsCount, 'childrenCount': childrenCount,
    'adultRate': adultRate, 'childRate': childRate,
    'food': food.toJson(), 'advance': advance,
    'paymentMode': paymentMode.name,
    'visitDate': visitDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'qrCode': qrCode, 'managerId': managerId, 'managerName': managerName,
    'qrUsed': qrUsed,
  };
  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
    id: j['id'], name: j['name'], city: j['city'] ?? '',
    phone: j['phone'] ?? '', packageId: j['packageId'] ?? '',
    packageName: j['packageName'] ?? '',
    adultsCount: j['adultsCount'] ?? 0, childrenCount: j['childrenCount'] ?? 0,
    adultRate: (j['adultRate'] ?? 0).toDouble(),
    childRate: (j['childRate'] ?? 0).toDouble(),
    food: FoodCounts.fromJson(j['food'] ?? {}),
    advance: (j['advance'] ?? 0).toDouble(),
    paymentMode: PaymentMode.values.firstWhere(
        (p) => p.name == j['paymentMode'], orElse: () => PaymentMode.cash),
    visitDate: DateTime.parse(j['visitDate']),
    createdAt: DateTime.parse(j['createdAt']),
    qrCode: j['qrCode'] ?? '', managerId: j['managerId'] ?? '',
    managerName: j['managerName'] ?? '', qrUsed: j['qrUsed'] ?? false,
  );
}

// ─── Worker ──────────────────────────────────────────────────────────────────
class WorkerModel {
  final String id, name, phone, city, role;
  final double payPerDay;
  final DateTime joiningDate;

  WorkerModel({required this.id, required this.name, required this.phone,
      required this.city, required this.role, required this.payPerDay,
      required this.joiningDate});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'city': city,
    'role': role, 'payPerDay': payPerDay,
    'joiningDate': joiningDate.toIso8601String(),
  };
  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
    id: j['id'], name: j['name'], phone: j['phone'] ?? '',
    city: j['city'] ?? '', role: j['role'] ?? '',
    payPerDay: (j['payPerDay'] ?? 0).toDouble(),
    joiningDate: DateTime.parse(j['joiningDate']),
  );
}

// ─── Worker Attendance ───────────────────────────────────────────────────────
class AttendanceRecord {
  final String workerId;
  final DateTime date;
  final bool present;
  AttendanceRecord({required this.workerId, required this.date, required this.present});

  Map<String, dynamic> toJson() => {
    'workerId': workerId, 'date': date.toIso8601String(), 'present': present,
  };
  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
    workerId: j['workerId'], date: DateTime.parse(j['date']), present: j['present'],
  );
}

// ─── Advance Payment ─────────────────────────────────────────────────────────
class AdvancePayment {
  final String id, workerId, workerName;
  final double amount;
  final DateTime date;
  AdvancePayment({required this.id, required this.workerId,
      required this.workerName, required this.amount, required this.date});

  Map<String, dynamic> toJson() => {
    'id': id, 'workerId': workerId, 'workerName': workerName,
    'amount': amount, 'date': date.toIso8601String(),
  };
  factory AdvancePayment.fromJson(Map<String, dynamic> j) => AdvancePayment(
    id: j['id'], workerId: j['workerId'], workerName: j['workerName'],
    amount: (j['amount'] ?? 0).toDouble(), date: DateTime.parse(j['date']),
  );
}

// ─── Salary Payment ──────────────────────────────────────────────────────────
class SalaryPayment {
  final String id, workerId, workerName;
  final int month, year;
  final double amount;
  final DateTime paidDate;
  SalaryPayment({required this.id, required this.workerId,
      required this.workerName, required this.month, required this.year,
      required this.amount, required this.paidDate});

  Map<String, dynamic> toJson() => {
    'id': id, 'workerId': workerId, 'workerName': workerName,
    'month': month, 'year': year, 'amount': amount,
    'paidDate': paidDate.toIso8601String(),
  };
  factory SalaryPayment.fromJson(Map<String, dynamic> j) => SalaryPayment(
    id: j['id'], workerId: j['workerId'], workerName: j['workerName'],
    month: j['month'], year: j['year'],
    amount: (j['amount'] ?? 0).toDouble(), paidDate: DateTime.parse(j['paidDate']),
  );
}

// ─── Enquiry ─────────────────────────────────────────────────────────────────
class EnquiryModel {
  final String id, name, city, phone;
  final DateTime date, createdAt;
  EnquiryModel({required this.id, required this.name, required this.city,
      required this.phone, required this.date, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'city': city, 'phone': phone,
    'date': date.toIso8601String(), 'createdAt': createdAt.toIso8601String(),
  };
  factory EnquiryModel.fromJson(Map<String, dynamic> j) => EnquiryModel(
    id: j['id'], name: j['name'], city: j['city'] ?? '',
    phone: j['phone'] ?? '', date: DateTime.parse(j['date']),
    createdAt: DateTime.parse(j['createdAt']),
  );
}
