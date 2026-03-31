import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'add_booking_screen.dart';
import 'qr_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  List<BookingModel> _allBookings = [];
  List<BookingModel> _filtered = [];
  bool _loading = true;
  String _searchText = '';
  String _batchFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    final result = await ApiService().getAllBookings();
    if (mounted) {
      if (result['success'] == true) {
        final list = result['bookings'] as List<dynamic>;
        _allBookings = list
            .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _applyFilter();
      }
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final search = _searchText.toLowerCase();
    _filtered = _allBookings.where((b) {
      final matchSearch = search.isEmpty ||
          b.customerName.toLowerCase().contains(search) ||
          b.mobile.contains(search) ||
          b.city.toLowerCase().contains(search);
      final matchBatch =
          _batchFilter == 'all' || b.batchType == _batchFilter;
      return matchSearch && matchBatch;
    }).toList();
  }

  Future<void> _deleteBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Booking?'),
        content: Text('Remove booking for ${booking.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && booking.id != null) {
      await ApiService().deleteBooking(booking.id!);
      _loadBookings();
    }
  }

  Widget _filterChip(String label, String value) {
    final selected = _batchFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _batchFilter = value;
          _applyFilter();
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white30,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
        _filtered.fold(0.0, (sum, b) => sum + b.totalAmount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    setState(() {
                      _searchText = v;
                      _applyFilter();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile, city...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textMedium,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: 6),
                      _filterChip('Full Day', 'full_day'),
                      const SizedBox(width: 6),
                      _filterChip('Morning', 'morning'),
                      const SizedBox(width: 6),
                      _filterChip('Afternoon', 'afternoon'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} bookings',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: Rs.${totalRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  )
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 56,
                              color: AppTheme.textLight,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No bookings found',
                              style: TextStyle(color: AppTheme.textMedium),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, index) {
                          final booking = _filtered[index];
                          return _BookingCard(
                            booking: booking,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddBookingScreen(
                                    booking: booking,
                                  ),
                                ),
                              ).then((_) => _loadBookings());
                            },
                            onDelete: () => _deleteBooking(booking),
                            onViewQR: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QRScreen(booking: booking),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewQR;

  const _BookingCard({
    required this.booking,
    required this.onEdit,
    required this.onDelete,
    required this.onViewQR,
  });

  Color get _batchColor {
    switch (booking.batchType) {
      case 'full_day':
        return const Color(0xFF1565C0);
      case 'morning':
        return const Color(0xFFE65100);
      case 'afternoon':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            booking.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _batchColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.batchType
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _batchColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.city}  -  ${booking.mobile}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs.${booking.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: booking.paymentMode == 'cash'
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.paymentMode.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: booking.paymentMode == 'cash'
                              ? AppTheme.secondary
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 13,
                  color: AppTheme.textLight,
                ),
                Text(
                  ' ${booking.totalGuests} guests  ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMedium,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: AppTheme.textLight,
                ),
                Text(
                  ' ${booking.bookingDate}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMedium,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.qr_code,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  onPressed: onViewQR,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
