import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import 'add_customer_screen.dart';
import 'qr_display_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final _db = DatabaseService();
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _db.getCustomers();
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((e) => CustomerModel.fromJson(e))
            .toList();
        setState(() {
          _customers = list;
          _filtered = list;
          _loading = false;
        });
      } else {
        setState(() { _error = res['message']; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load customers'; _loading = false; });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _customers
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q) ||
              c.mobile.contains(q))
          .toList();
    });
  }

  Future<void> _delete(CustomerModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${c.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _db.deleteCustomer(c.id!);
      if (!mounted) return;
      if (res['success'] == true) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Delete failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, city or mobile...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter();
                        })
                    : null,
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
                child: Center(
                    child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!,
                    style:
                        GoogleFonts.poppins(color: AppTheme.error)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            )))
          else if (_filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 12),
                    Text('No customers found',
                        style: GoogleFonts.poppins(color: AppTheme.textLight)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _customerCard(_filtered[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _customerCard(CustomerModel c) {
    final pkg = allPackages.firstWhere((p) => p.id == c.packageId,
        orElse: () => allPackages[0]);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textDark)),
                      Text('${c.city} • ${c.mobile}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.paymentMode == 'cash'
                        ? AppTheme.cashColor.withOpacity(0.1)
                        : AppTheme.onlineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.paymentMode == 'cash' ? '💵 Cash' : '📱 Online',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: c.paymentMode == 'cash'
                          ? AppTheme.cashColor
                          : AppTheme.onlineColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _info('Package', pkg.name,
                          icon: Icons.card_membership)),
                  Expanded(
                      child: _info('Guests', c.totalGuests.toString(),
                          icon: Icons.people)),
                  Expanded(
                      child: _info('Amount',
                          '₹${c.totalAmount.toStringAsFixed(0)}',
                          icon: Icons.currency_rupee)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // QR
                OutlinedButton.icon(
                  onPressed: c.qrToken != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrDisplayScreen(
                                qrToken: c.qrToken!,
                                customerName: c.name,
                                packageName: pkg.nameMarathi,
                                totalGuests: c.totalGuests,
                                totalAmount: c.totalAmount,
                                customerId: c.id ?? 0,
                              ),
                            ),
                          )
                      : null,
                  icon: Icon(
                    c.qrUsed ? Icons.qr_code_2 : Icons.qr_code,
                    size: 16,
                  ),
                  label: Text(c.qrUsed ? 'QR Used' : 'View QR',
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        c.qrUsed ? AppTheme.textLight : AppTheme.primary,
                    side: BorderSide(
                        color: c.qrUsed
                            ? AppTheme.textLight
                            : AppTheme.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
                const Spacer(),
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.teal, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddCustomerScreen(editCustomer: c),
                    ),
                  ).then((updated) {
                    if (updated == true) _load();
                  }),
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.error, size: 20),
                  onPressed: () => _delete(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value, {required IconData icon}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textLight),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppTheme.textLight)),
      ],
    );
  }
}
