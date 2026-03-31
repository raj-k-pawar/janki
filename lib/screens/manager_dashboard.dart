import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'add_booking_screen.dart';
import 'all_customers_screen.dart';
import 'workers_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});
  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  late String _today;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService().getDashboardStats(_today);
    if (mounted) setState(() { _stats = r['stats'] ?? {}; _loading = false; });
  }

  String _fmt(dynamic v) => '₹${(double.tryParse(v?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final now = DateTime.now();
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${days[now.weekday-1]}, ${now.day} ${months[now.month-1]} ${now.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primary,
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.name}', style: const TextStyle(fontSize: 13, color: Colors.white)),
            Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: () { Navigator.pop(context); context.read<AuthProvider>().logout(); },
                  child: const Text('Logout'),
                ),
              ],
            )),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF43A047)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,5))],
              ),
              child: Row(children: [
                const Icon(Icons.dashboard_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Today's Overview", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                if (_loading) const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              ]),
            ),
            const SizedBox(height: 14),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _Stat('Total Bookings', _stats['total_bookings']?.toString() ?? '0', Icons.confirmation_num_outlined, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                _Stat('Total Guests', _stats['total_guests']?.toString() ?? '0', Icons.people_outline, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
                _Stat('Total Revenue', _fmt(_stats['total_revenue']), Icons.account_balance_wallet_outlined, AppTheme.primary, const Color(0xFFE8F5E9)),
                _Stat('Cash Payment', _fmt(_stats['cash_payment']), Icons.money, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                _Stat('Online Payment', _fmt(_stats['online_payment']), Icons.phone_android, const Color(0xFF00695C), const Color(0xFFE0F2F1)),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 10),
            _Action(Icons.person_add_rounded, 'Add New Customer', 'Create a new booking', AppTheme.primary,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookingScreen())).then((_) => _load())),
            const SizedBox(height: 8),
            _Action(Icons.list_alt_rounded, 'View All Customers', 'See all bookings', AppTheme.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCustomersScreen())).then((_) => _load())),
            const SizedBox(height: 8),
            _Action(Icons.badge_rounded, 'Manage Workers', 'Staff management', AppTheme.secondary,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkersScreen()))),
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _Stat(this.label, this.value, this.icon, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: color, size: 26),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.sub, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(14), elevation: 1.5,
    child: InkWell(
      borderRadius: BorderRadius.circular(14), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        ])),
        Icon(Icons.chevron_right, color: color),
      ])),
    ),
  );
}
