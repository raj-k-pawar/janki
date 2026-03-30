// lib/screens/qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import 'manager_dashboard.dart';

class QRScreen extends StatelessWidget {
  final BookingModel booking;
  const QRScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final foods = <String>[];
    if (booking.foodBreakfast) foods.add('🥞 Breakfast');
    if (booking.foodLunch) foods.add('🍱 Lunch');
    if (booking.foodHighTea) foods.add('☕ High Tea');
    if (booking.foodDinner) foods.add('🍽️ Dinner');

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
              MaterialPageRoute(builder: (_) => const ManagerDashboard()),
              (route) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF43A047)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking Confirmed!', style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Canteen QR code generated below', style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Details Card
            _infoCard('Customer Details', [
              _detailRow('Name', booking.customerName, Icons.person),
              _detailRow('City', booking.city, Icons.location_city),
              _detailRow('Mobile', booking.mobile, Icons.phone),
              _detailRow('Batch', booking.batchLabel, Icons.schedule),
              _detailRow('Booking ID', '#${booking.id}', Icons.confirmation_num),
            ]),
            const SizedBox(height: 14),

            // Guest & Amount Card
            _infoCard('Guest & Payment', [
              _detailRow('Guests (10+)', '${booking.guestsAbove10}', Icons.group),
              _detailRow('Guests (3-10)', '${booking.guests3To10}', Icons.child_care),
              _detailRow('Total Guests', '${booking.totalGuests}', Icons.people),
              _detailRow('Payment Mode', booking.paymentMode.toUpperCase(), Icons.payment),
              _amountRow('Total Amount', '₹${booking.totalAmount.toStringAsFixed(0)}'),
            ]),
            const SizedBox(height: 14),

            // Food Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Food Included', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: foods.map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(f, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QR Code
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('🍽️  Canteen QR Code', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  const Text('Show this to canteen staff for food service',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMedium), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: booking.generateQrData(),
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primary),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 14),
                  Text('Booking #${booking.id} • ${booking.customerName}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const ManagerDashboard()),
                    (route) => false),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
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
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const Divider(height: 16),
        ...rows,
      ],
    ),
  );

  Widget _detailRow(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 16, color: AppTheme.textLight),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        textAlign: TextAlign.right)),
    ]),
  );

  Widget _amountRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      const Icon(Icons.currency_rupee, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary),
        textAlign: TextAlign.right)),
    ]),
  );
}
