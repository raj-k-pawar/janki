// lib/screens/manager_dashboard.dart
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
  String _today = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final result = await ApiService().getDashboardStats(_today);
    if (result['success'] == true && mounted) {
      setState(() {
        _stats = result['stats'] ?? {};
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _formatCurrency(dynamic val) {
    final amount = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final now = DateTime.now();
    final dateStr = '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)} ${now.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user.name}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Overview", style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                          )),
                          Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_loading)
                      const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    label: 'Total Bookings',
                    value: _stats['total_bookings']?.toString() ?? '0',
                    icon: Icons.confirmation_num_outlined,
                    color: const Color(0xFF1565C0),
                    bgColor: const Color(0xFFE3F2FD),
                  ),
                  _StatCard(
                    label: 'Total Guests',
                    value: _stats['total_guests']?.toString() ?? '0',
                    icon: Icons.people_outline,
                    color: const Color(0xFF6A1B9A),
                    bgColor: const Color(0xFFF3E5F5),
                  ),
                  _StatCard(
                    label: 'Total Revenue',
                    value: _formatCurrency(_stats['total_revenue']),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.primary,
                    bgColor: const Color(0xFFE8F5E9),
                  ),
                  _StatCard(
                    label: 'Cash Payment',
                    value: _formatCurrency(_stats['cash_payment']),
                    icon: Icons.money,
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                  ),
                  _StatCard(
                    label: 'Online Payment',
                    value: _formatCurrency(_stats['online_payment']),
                    icon: Icons.phone_android,
                    color: const Color(0xFF00695C),
                    bgColor: const Color(0xFFE0F2F1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              const Text('Quick Actions', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark,
              )),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.person_add_rounded,
                label: 'Add New Customer',
                subtitle: 'Create a new booking',
                color: AppTheme.primary,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddBookingScreen())).then((_) => _loadStats()),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.list_alt_rounded,
                label: 'View All Customers',
                subtitle: 'See all bookings',
                color: AppTheme.accent,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllCustomersScreen())).then((_) => _loadStats()),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.badge_rounded,
                label: 'Manage Workers',
                subtitle: 'Staff management',
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WorkersScreen())),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _dayName(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bgColor;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: color, size: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    ),
  );
}
