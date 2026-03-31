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
  List<BookingModel> _all = [], _filtered = [];
  bool _loading = true;
  String _search = '', _batch = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService().getAllBookings();
    if (r['success'] == true && mounted) {
      setState(() {
        _all = (r['bookings'] as List).map((j) => BookingModel.fromJson(j)).toList();
        _applyFilter();
        _loading = false;
      });
    } else { setState(() => _loading = false); }
  }

  void _applyFilter() {
    _filtered = _all.where((b) {
      final s = _search.toLowerCase();
      final matchS = _search.isEmpty || b.customerName.toLowerCase().contains(s)
          || b.mobile.contains(s) || b.city.toLowerCase().contains(s);
      final matchB = _batch == 'all' || b.batchType == _batch;
      return matchS && matchB;
    }).toList();
  }

  Future<void> _delete(BookingModel b) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Booking?'),
      content: Text('Remove booking for ${b.customerName}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ));
    if (ok == true) {
      await ApiService().deleteBooking(b.id!);
      _load();
    }
  }

  Widget _chip(String label, String val) => GestureDetector(
    onTap: () => setState(() { _batch = val; _applyFilter(); }),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _batch == val ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          color: _batch == val ? AppTheme.primary : Colors.white,
          fontWeight: FontWeight.w600, fontSize: 12)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(title: const Text('All Customers'), backgroundColor: AppTheme.primary,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)]),
    body: Column(children: [
      Container(color: AppTheme.primary, padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(children: [
        TextField(
          onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
          decoration: InputDecoration(
            hintText: 'Search by name, mobile, city...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textMedium),
            filled: true, fillColor: Colors.white, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _chip('All', 'all'), const SizedBox(width: 6),
          _chip('Full Day', 'full_day'), const SizedBox(width: 6),
          _chip('Morning', 'morning'), const SizedBox(width: 6),
          _chip('Afternoon', 'afternoon'),
        ])),
      ])),
      Container(
        color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Text('${_filtered.length} bookings', style: const TextStyle(fontSize: 12, color: AppTheme.textMedium, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Total: ₹${_filtered.fold(0.0, (s, b) => s + b.totalAmount).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _filtered.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_outline, size: 56, color: AppTheme.textLight),
                  SizedBox(height: 10),
                  Text('No bookings found', style: TextStyle(color: AppTheme.textMedium)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _BookingCard(
                    booking: _filtered[i],
                    onEdit: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddBookingScreen(booking: _filtered[i]))).then((_) => _load()),
                    onDelete: () => _delete(_filtered[i]),
                    onQR: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => QRScreen(booking: _filtered[i]))),
                  ),
                )),
    ]),
  );
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onEdit, onDelete, onQR;
  const _BookingCard({required this.booking, required this.onEdit, required this.onDelete, required this.onQR});

  Color get _batchColor => switch (booking.batchType) {
    'full_day' => const Color(0xFF1565C0),
    'morning' => const Color(0xFFE65100),
    'afternoon' => const Color(0xFF6A1B9A),
    _ => AppTheme.primary,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 1.5,
    child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(booking.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _batchColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(booking.batchType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _batchColor)),
            ),
          ]),
          const SizedBox(height: 2),
          Text('${booking.city}  •  ${booking.mobile}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${booking.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: booking.paymentMode == 'cash' ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(booking.paymentMode.toUpperCase(), style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: booking.paymentMode == 'cash' ? AppTheme.secondary : AppTheme.primary)),
          ),
        ]),
      ]),
      const Divider(height: 12),
      Row(children: [
        const Icon(Icons.people, size: 13, color: AppTheme.textLight),
        Text(' ${booking.totalGuests} guests  ', style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        const Icon(Icons.calendar_today, size: 13, color: AppTheme.textLight),
        Text(' ${booking.bookingDate}', style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.qr_code, color: AppTheme.accent, size: 20), onPressed: onQR,
            padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 14),
        IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20), onPressed: onEdit,
            padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 14),
        IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20), onPressed: onDelete,
            padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    ])),
  );
}
