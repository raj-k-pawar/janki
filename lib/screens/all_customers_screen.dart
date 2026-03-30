// lib/screens/all_customers_screen.dart
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
  List<BookingModel> _bookings = [];
  List<BookingModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _filterBatch = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    final result = await ApiService().getAllBookings();
    if (result['success'] == true && mounted) {
      final list = (result['bookings'] as List)
          .map((j) => BookingModel.fromJson(j))
          .toList();
      setState(() {
        _bookings = list;
        _applyFilter();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered = _bookings.where((b) {
      final matchSearch = _search.isEmpty ||
          b.customerName.toLowerCase().contains(_search.toLowerCase()) ||
          b.mobile.contains(_search) ||
          b.city.toLowerCase().contains(_search.toLowerCase());
      final matchBatch = _filterBatch == 'all' || b.batchType == _filterBatch;
      return matchSearch && matchBatch;
    }).toList();
  }

  Future<void> _delete(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Booking?'),
        content: Text('Are you sure you want to delete booking for ${booking.customerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService().deleteBooking(booking.id!);
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted'), backgroundColor: AppTheme.primary));
        _loadBookings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadBookings),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile, city...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMedium),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('Full Day', 'full_day'),
                      const SizedBox(width: 8),
                      _filterChip('Morning', 'morning'),
                      const SizedBox(width: 8),
                      _filterChip('Afternoon', 'afternoon'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Text('${_filtered.length} bookings', style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textMedium, fontSize: 13)),
                const Spacer(),
                Text(
                  'Total: ₹${_filtered.fold(0.0, (s, b) => s + b.totalAmount).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtered.isEmpty
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 60, color: AppTheme.textLight),
                          SizedBox(height: 12),
                          Text('No bookings found', style: TextStyle(color: AppTheme.textMedium)),
                        ],
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _filtered[i],
                          onEdit: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddBookingScreen(booking: _filtered[i]))).then((_) => _loadBookings()),
                          onDelete: () => _delete(_filtered[i]),
                          onQR: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => QRScreen(booking: _filtered[i]))),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) => GestureDetector(
    onTap: () => setState(() { _filterBatch = value; _applyFilter(); }),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _filterBatch == value ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        color: _filterBatch == value ? AppTheme.primary : Colors.white,
        fontWeight: FontWeight.w600, fontSize: 12,
      )),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onEdit, onDelete, onQR;

  const _BookingCard({required this.booking, required this.onEdit, required this.onDelete, required this.onQR});

  Color get _batchColor {
    switch (booking.batchType) {
      case 'full_day': return const Color(0xFF1565C0);
      case 'morning': return const Color(0xFFE65100);
      case 'afternoon': return const Color(0xFF6A1B9A);
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(booking.customerName, style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _batchColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(booking.batchType.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _batchColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on, size: 13, color: AppTheme.textLight),
                      Text(' ${booking.city}  ', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                      const Icon(Icons.phone, size: 13, color: AppTheme.textLight),
                      Text(' ${booking.mobile}', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${booking.totalAmount.toStringAsFixed(0)}', style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: booking.paymentMode == 'cash' ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(booking.paymentMode.toUpperCase(), style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: booking.paymentMode == 'cash' ? AppTheme.secondary : AppTheme.primary)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            children: [
              _infoChip(Icons.people, '${booking.totalGuests} guests'),
              const SizedBox(width: 8),
              _infoChip(Icons.calendar_today, booking.bookingDate),
              const Spacer(),
              IconButton(icon: const Icon(Icons.qr_code, color: AppTheme.accent, size: 22), onPressed: onQR, tooltip: 'View QR', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 22), onPressed: onEdit, tooltip: 'Edit', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 22), onPressed: onDelete, tooltip: 'Delete', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _infoChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 13, color: AppTheme.textLight),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
    ],
  );
}
