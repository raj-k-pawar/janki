import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import 'manager_dashboard.dart';
import 'add_booking_screen.dart';

class QRScreen extends StatelessWidget {
  final BookingModel booking;
  const QRScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final foods = [
      if (booking.foodBreakfast) '🥞 Breakfast',
      if (booking.foodLunch) '🍱 Lunch',
      if (booking.foodHighTea) '☕ High Tea',
      if (booking.foodDinner) '🍽️ Dinner',
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppTheme.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const ManagerDashboard()), (_) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Success
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF43A047)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 34),
              SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                Text('Canteen QR code generated', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          _card([
            _row('Customer', booking.customerName, Icons.person),
            _row('City', booking.city, Icons.location_city),
            _row('Mobile', booking.mobile, Icons.phone),
            _row('Batch', booking.batchLabel, Icons.schedule),
            _row('Booking ID', '#${booking.id}', Icons.confirmation_num),
          ]),

          _card([
            _row('Guests (10+)', '${booking.guestsAbove10}', Icons.group),
            _row('Guests (3-10)', '${booking.guests3To10}', Icons.child_care),
            _row('Total Guests', '${booking.totalGuests}', Icons.people),
            _row('Payment', booking.paymentMode.toUpperCase(), Icons.payment),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.currency_rupee, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                const Text('Total Amount:', style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                const Spacer(),
                Text('₹${booking.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              ]),
            ),
          ]),

          _card([
            const Text('Food Included', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: foods.map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Text(f, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            )).toList()),
          ]),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0,4))],
            ),
            child: Column(children: [
              const Text('🍽️  Canteen QR Code',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              const Text('Show to canteen staff for food service',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMedium), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              QrImageView(
                data: booking.generateQrData(),
                version: QrVersions.auto,
                size: 210,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primary),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textDark),
              ),
              const SizedBox(height: 10),
              Text('Booking #${booking.id} • ${booking.customerName}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ]),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const ManagerDashboard()), (_) => false),
                icon: const Icon(Icons.dashboard, color: AppTheme.primary),
                label: const Text('Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AddBookingScreen())),
                icon: const Icon(Icons.add),
                label: const Text('New Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _card(List<Widget> kids) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: kids),
  );

  Widget _row(String label, String val, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 15, color: AppTheme.textLight),
      const SizedBox(width: 6),
      Text('$label:', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
      const Spacer(),
      Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    ]),
  );
}
