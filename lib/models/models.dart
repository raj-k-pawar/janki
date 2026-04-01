// ─── USER MODEL ──────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String role; // manager | owner | admin | canteen
  final String mobile;
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.mobile,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: int.tryParse(j['id'].toString()) ?? 0,
        username: j['username'] ?? '',
        fullName: j['full_name'] ?? '',
        role: j['role'] ?? '',
        mobile: j['mobile'] ?? '',
        token: j['token'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'role': role,
        'mobile': mobile,
      };
}

// ─── PACKAGE MODEL ───────────────────────────────────────────────────────────
class PackageModel {
  final String id;
  final String name;
  final String nameMarathi;
  final String timing;
  final int priceAbove10;
  final int price3to10;
  final String includes;

  PackageModel({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.timing,
    required this.priceAbove10,
    required this.price3to10,
    required this.includes,
  });
}

final List<PackageModel> allPackages = [
  PackageModel(
    id: 'half_day_morning',
    name: 'Half Day Morning',
    nameMarathi: '🌞 सकाळी हाफ डे पॅकेज',
    timing: '🕙 सकाळी 10:00 ते दुपारी 03:00',
    priceAbove10: 500,
    price3to10: 400,
    includes: '☕ चहा | 🍽️ नाश्ता | 🍛 जेवण',
  ),
  PackageModel(
    id: 'half_day_evening',
    name: 'Half Day Evening',
    nameMarathi: '🌅 सायंकाळी हाफ डे पॅकेज',
    timing: '🕒 दुपारी 03:00 ते सायंकाळी 08:00',
    priceAbove10: 500,
    price3to10: 400,
    includes: '☕ चहा | 🍽️ नाश्ता | 🍛 जेवण',
  ),
  PackageModel(
    id: 'full_day',
    name: 'Full Day',
    nameMarathi: '🌟 फुल डे पॅकेज',
    timing: '🕙 सकाळी 10:00 ते सायंकाळी 06:00',
    priceAbove10: 650,
    price3to10: 500,
    includes: '☕ चहा | 🍽️ नाश्ता | 🍛 जेवण',
  ),
  PackageModel(
    id: 'ac_room',
    name: 'AC Deluxe Room',
    nameMarathi: '🏨 A C डिलक्स रूम पॅकेज ❄️',
    timing: '🕙 सकाळी 10:00 ते दुसऱ्या दिवशी सकाळी 09:30',
    priceAbove10: 1800,
    price3to10: 1300,
    includes: '🍽️ 2 वेळ जेवण | 🥪 3 वेळ चहा व नाश्ता',
  ),
  PackageModel(
    id: 'non_ac_room',
    name: 'Non AC Room',
    nameMarathi: '🏠 Non A C रूम पॅकेज 🌿',
    timing: '🕙 सकाळी 10:00 ते दुसऱ्या दिवशी सकाळी 09:30',
    priceAbove10: 1500,
    price3to10: 1100,
    includes: '🍽️ 2 वेळ जेवण | 🥪 3 वेळ चहा व नाश्ता',
  ),
];

// ─── CUSTOMER MODEL ───────────────────────────────────────────────────────────
class CustomerModel {
  final int? id;
  final String name;
  final String city;
  final String mobile;
  final String packageId;
  final int guestsAbove10;
  final int guests3to10;
  final double amountAbove10;
  final double amount3to10;
  final double totalAmount;
  final String paymentMode; // cash | online
  final bool lunchDinner;
  final bool breakfast;
  final int lunchDinnerCount;
  final String? qrToken;
  final DateTime? createdAt;
  final bool qrUsed;

  CustomerModel({
    this.id,
    required this.name,
    required this.city,
    required this.mobile,
    required this.packageId,
    required this.guestsAbove10,
    required this.guests3to10,
    required this.amountAbove10,
    required this.amount3to10,
    required this.totalAmount,
    required this.paymentMode,
    required this.lunchDinner,
    required this.breakfast,
    required this.lunchDinnerCount,
    this.qrToken,
    this.createdAt,
    this.qrUsed = false,
  });

  int get totalGuests => guestsAbove10 + guests3to10;

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
        id: int.tryParse(j['id'].toString()),
        name: j['name'] ?? '',
        city: j['city'] ?? '',
        mobile: j['mobile'] ?? '',
        packageId: j['package_id'] ?? '',
        guestsAbove10: int.tryParse(j['guests_above_10'].toString()) ?? 0,
        guests3to10: int.tryParse(j['guests_3to10'].toString()) ?? 0,
        amountAbove10: double.tryParse(j['amount_above_10'].toString()) ?? 0,
        amount3to10: double.tryParse(j['amount_3to10'].toString()) ?? 0,
        totalAmount: double.tryParse(j['total_amount'].toString()) ?? 0,
        paymentMode: j['payment_mode'] ?? 'cash',
        lunchDinner: j['lunch_dinner'] == 1 || j['lunch_dinner'] == true,
        breakfast: j['breakfast'] == 1 || j['breakfast'] == true,
        lunchDinnerCount:
            int.tryParse(j['lunch_dinner_count'].toString()) ?? 0,
        qrToken: j['qr_token'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
        qrUsed: j['qr_used'] == 1 || j['qr_used'] == true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': city,
        'mobile': mobile,
        'package_id': packageId,
        'guests_above_10': guestsAbove10,
        'guests_3to10': guests3to10,
        'amount_above_10': amountAbove10,
        'amount_3to10': amount3to10,
        'total_amount': totalAmount,
        'payment_mode': paymentMode,
        'lunch_dinner': lunchDinner ? 1 : 0,
        'breakfast': breakfast ? 1 : 0,
        'lunch_dinner_count': lunchDinnerCount,
      };
}

// ─── WORKER MODEL ─────────────────────────────────────────────────────────────
class WorkerModel {
  final int? id;
  final String name;
  final String role;
  final String mobile;
  final double salary;
  final String status; // active | inactive

  WorkerModel({
    this.id,
    required this.name,
    required this.role,
    required this.mobile,
    required this.salary,
    required this.status,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
        id: int.tryParse(j['id'].toString()),
        name: j['name'] ?? '',
        role: j['role'] ?? '',
        mobile: j['mobile'] ?? '',
        salary: double.tryParse(j['salary'].toString()) ?? 0,
        status: j['status'] ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'mobile': mobile,
        'salary': salary,
        'status': status,
      };
}

// ─── DASHBOARD MODEL ──────────────────────────────────────────────────────────
class DashboardModel {
  final int totalBookings;
  final int totalGuests;
  final double totalRevenue;
  final double cashPayment;
  final double onlinePayment;

  DashboardModel({
    required this.totalBookings,
    required this.totalGuests,
    required this.totalRevenue,
    required this.cashPayment,
    required this.onlinePayment,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> j) => DashboardModel(
        totalBookings: int.tryParse(j['total_bookings'].toString()) ?? 0,
        totalGuests: int.tryParse(j['total_guests'].toString()) ?? 0,
        totalRevenue: double.tryParse(j['total_revenue'].toString()) ?? 0,
        cashPayment: double.tryParse(j['cash_payment'].toString()) ?? 0,
        onlinePayment: double.tryParse(j['online_payment'].toString()) ?? 0,
      );
}
