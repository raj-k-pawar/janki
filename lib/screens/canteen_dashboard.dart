import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'qr_screen.dart';

class CanteenDashboard extends StatefulWidget {
  const CanteenDashboard({super.key});

  @override
  State<CanteenDashboard> createState() => _CanteenDashboardState();
}

class _CanteenDashboardState extends State<CanteenDashboard> {
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayBookings();
  }

  Future<void> _loadTodayBookings() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final today = '${now.year}-$m-$d';

    final result = await ApiService().getBookings(date: today);
    if (mounted) {
      if (result['success'] == true) {
        final list = result['bookings'] as List<dynamic>;
        _bookings = list
            .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGuests =
        _bookings.fold(0, (sum, b) => sum + b.totalGuests);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.secondary,
        title: const Text('Canteen Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTodayBookings,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            color: AppTheme.secondary,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(
              children: [
                _statBox(
                  "Today's Bookings",
                  '${_bookings.length}',
                  Icons.confirmation_num,
                ),
                const SizedBox(width: 10),
                _statBox(
                  'Total Guests',
                  '$totalGuests',
                  Icons.people,
                ),
              ],
            ),
          ),
          // Bookings list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondary,
                    ),
                  )
                : _bookings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 56,
                              color: AppTheme.textLight,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No bookings today',
                              style: TextStyle(color: AppTheme.textMedium),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (_, index) {
                          final booking = _bookings[index];
                          final foods = <String>[];
                          if (booking.foodBreakfast) foods.add('Breakfast');
                          if (booking.foodLunch) foods.add('Lunch');
                          if (booking.foodHighTea) foods.add('High Tea');
                          if (booking.foodDinner) foods.add('Dinner');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking.customerName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${booking.totalGuests} guests',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QRScreen(
                                                booking: booking,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.qr_code,
                                          color: AppTheme.accent,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.batchLabel,
                                    style: const TextStyle(
                                      color: AppTheme.textMedium,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: foods.map((food) {
                                      return Chip(
                                        label: Text(
                                          food,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor:
                                            AppTheme.secondary.withOpacity(0.1),
                                        side: BorderSide(
                                          color: AppTheme.secondary
                                              .withOpacity(0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
