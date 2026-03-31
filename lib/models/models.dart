class UserModel {
  final int id;
  final String username;
  final String role;
  final String name;

  UserModel({required this.id, required this.username, required this.role, required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        username: json['username'] ?? '',
        role: json['role'] ?? 'manager',
        name: json['name'] ?? '',
      );

  bool get isManager => role == 'manager' || role == 'owner' || role == 'admin';
  bool get isCanteen => role == 'canteen';
}

class BookingModel {
  int? id;
  String customerName;
  String city;
  String mobile;
  String batchType;
  int guestsAbove10;
  double amountAbove10;
  int guests3To10;
  double amount3To10;
  bool foodBreakfast;
  bool foodLunch;
  bool foodHighTea;
  bool foodDinner;
  int totalGuests;
  double totalAmount;
  String paymentMode;
  String? qrCode;
  String bookingDate;
  String? createdAt;

  BookingModel({
    this.id,
    this.customerName = '',
    this.city = '',
    this.mobile = '',
    this.batchType = 'full_day',
    this.guestsAbove10 = 0,
    this.amountAbove10 = 0,
    this.guests3To10 = 0,
    this.amount3To10 = 0,
    this.foodBreakfast = true,
    this.foodLunch = true,
    this.foodHighTea = false,
    this.foodDinner = false,
    this.totalGuests = 0,
    this.totalAmount = 0,
    this.paymentMode = 'cash',
    this.qrCode,
    String? bookingDate,
    this.createdAt,
  }) : bookingDate = bookingDate ?? _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: int.tryParse(json['id'].toString()),
        customerName: json['customer_name'] ?? '',
        city: json['city'] ?? '',
        mobile: json['mobile'] ?? '',
        batchType: json['batch_type'] ?? 'full_day',
        guestsAbove10: int.tryParse(json['guests_above_10'].toString()) ?? 0,
        amountAbove10: double.tryParse(json['amount_above_10'].toString()) ?? 0,
        guests3To10: int.tryParse(json['guests_3_to_10'].toString()) ?? 0,
        amount3To10: double.tryParse(json['amount_3_to_10'].toString()) ?? 0,
        foodBreakfast: json['food_breakfast'].toString() == '1',
        foodLunch: json['food_lunch'].toString() == '1',
        foodHighTea: json['food_high_tea'].toString() == '1',
        foodDinner: json['food_dinner'].toString() == '1',
        totalGuests: int.tryParse(json['total_guests'].toString()) ?? 0,
        totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0,
        paymentMode: json['payment_mode'] ?? 'cash',
        qrCode: json['qr_code'],
        bookingDate: json['booking_date'] ?? _today(),
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'customer_name': customerName,
        'city': city,
        'mobile': mobile,
        'batch_type': batchType,
        'guests_above_10': guestsAbove10,
        'amount_above_10': amountAbove10,
        'guests_3_to_10': guests3To10,
        'amount_3_to_10': amount3To10,
        'food_breakfast': foodBreakfast,
        'food_lunch': foodLunch,
        'food_high_tea': foodHighTea,
        'food_dinner': foodDinner,
        'total_guests': totalGuests,
        'total_amount': totalAmount,
        'payment_mode': paymentMode,
        'qr_code': qrCode,
        'booking_date': bookingDate,
      };

  String get batchLabel {
    switch (batchType) {
      case 'full_day': return 'Full Day (10AM–6PM)';
      case 'morning':  return 'Morning (10AM–3PM)';
      case 'afternoon': return 'Afternoon (3PM–8PM)';
      default: return batchType;
    }
  }

  String generateQrData() {
    final foods = <String>[];
    if (foodBreakfast) foods.add('Breakfast');
    if (foodLunch) foods.add('Lunch');
    if (foodHighTea) foods.add('High Tea');
    if (foodDinner) foods.add('Dinner');
    return 'JANKI AGRO TOURISM\n'
        'ID: ${id ?? "NEW"}\n'
        'Customer: $customerName\n'
        'Batch: $batchLabel\n'
        'Guests (10+): $guestsAbove10\n'
        'Guests (3-10): $guests3To10\n'
        'Total Guests: $totalGuests\n'
        'Food: ${foods.join(", ")}\n'
        'Amount: ₹${totalAmount.toStringAsFixed(0)}\n'
        'Payment: ${paymentMode.toUpperCase()}\n'
        'Date: $bookingDate';
  }

  double getFoodDeduction() {
    double d = 0;
    final isFullDay = batchType == 'full_day';
    final isMorning = batchType == 'morning';
    final isAfternoon = batchType == 'afternoon';
    if (!foodBreakfast && (isFullDay || isMorning)) d += 50 * totalGuests;
    if (!foodLunch && (isFullDay || isMorning)) d += 100 * totalGuests;
    if (!foodHighTea && (isFullDay || isAfternoon)) d += 50 * totalGuests;
    if (!foodDinner && isAfternoon) d += 100 * totalGuests;
    return d;
  }
}

class WorkerModel {
  int? id;
  String name;
  String role;
  String mobile;
  double salary;
  String joiningDate;
  String status;

  WorkerModel({
    this.id,
    this.name = '',
    this.role = '',
    this.mobile = '',
    this.salary = 0,
    String? joiningDate,
    this.status = 'active',
  }) : joiningDate = joiningDate ?? _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel(
        id: int.tryParse(json['id'].toString()),
        name: json['name'] ?? '',
        role: json['role'] ?? '',
        mobile: json['mobile'] ?? '',
        salary: double.tryParse(json['salary'].toString()) ?? 0,
        joiningDate: json['joining_date'] ?? _today(),
        status: json['status'] ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'mobile': mobile,
        'salary': salary,
        'joining_date': joiningDate,
        'status': status,
      };
}
