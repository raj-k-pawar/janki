import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';

class CanteenDashboard extends StatefulWidget {
  final UserModel user;
  const CanteenDashboard({super.key, required this.user});
  @override State<CanteenDashboard> createState() => _CanteenDashboardState();
}

class _CanteenDashboardState extends State<CanteenDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4D6E), Color(0xFF0A9396), Color(0xFF48CAE4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(13)),
                  child: Center(child: Text(widget.user.fullName[0].toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 20,
                          fontWeight: FontWeight.w700, color: Colors.white)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Canteen Staff', style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white70)),
                  Text(widget.user.fullName, style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ])),
                GestureDetector(
                  onTap: () async {
                    await StorageService.instance.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  },
                  child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20))),
              ])),
            // TAB 1 = Scan QR, TAB 2 = All Customers
            TabBar(controller: _tab,
              tabs: const [Tab(text: 'Scan QR Code'), Tab(text: 'All Customers')],
              indicatorColor: Colors.white, labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ])),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _ScanQrTab(canteenUser: widget.user),
          _CustomerListTab(canteenUser: widget.user),
        ])),
      ]),
    );
  }
}

// ══ Scan QR Tab ════════════════════════════════════════════════════════════
class _ScanQrTab extends StatefulWidget {
  final UserModel canteenUser;
  const _ScanQrTab({required this.canteenUser});
  @override State<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<_ScanQrTab> {
  final _ctrl = TextEditingController();
  String? _resultMsg;
  Color   _resultColor = AppColors.success;
  IconData _resultIcon = Icons.check_circle_outline;
  CustomerModel? _found;
  bool _processing = false;
  bool _scanning = false;  // simulated camera state

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _validate(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    setState(() { _processing = true; _scanning = false; });

    final all   = await StorageService.instance.getCustomers();
    final today = DateTime.now();
    CustomerModel? customer;
    for (final c in all) {
      if (c.qrCode == trimmed) { customer = c; break; }
    }

    if (customer == null) {
      setState(() {
        _resultMsg   = 'QR code not found.\nInvalid or unrecognised code.';
        _resultColor = AppColors.error;
        _resultIcon  = Icons.cancel_outlined;
        _found = null;
        _processing = false;
      });
      return;
    }

    final isToday = sameDay(customer.visitDate, today);
    if (!isToday) {
      setState(() {
        _resultMsg   = 'QR not valid for today.\n'
            'Booked for: ${DateFormat('dd MMM yyyy').format(customer!.visitDate)}';
        _resultColor = AppColors.warning;
        _resultIcon  = Icons.warning_amber_outlined;
        _found = customer;
        _processing = false;
      });
      return;
    }

    if (customer.canteenServed) {
      setState(() {
        _resultMsg   = 'Already served!\nThis QR was already scanned today.';
        _resultColor = AppColors.warning;
        _resultIcon  = Icons.info_outline;
        _found = customer;
        _processing = false;
      });
      return;
    }

    // ✅ Mark served
    await StorageService.instance.markCanteenServed(customer.id);
    _ctrl.clear();
    setState(() {
      _resultMsg   = 'Valid! Customer marked as SERVED.';
      _resultColor = AppColors.success;
      _resultIcon  = Icons.check_circle_outline;
      _found = customer;
      _processing = false;
    });
  }

  // Simulated scanner that parses QR-like codes entered via text
  void _startScanner() {
    setState(() => _scanning = !_scanning);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Camera scanner simulation panel
        const SectionHeader('Camera QR Scanner', icon: Icons.qr_code_scanner),
        GestureDetector(
          onTap: _startScanner,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: _scanning ? const Color(0xFF0A4D6E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _scanning ? const Color(0xFF0A9396) : Colors.grey.shade300,
                width: 2)),
            child: _scanning
              ? Stack(alignment: Alignment.center, children: [
                  // Scanner animation
                  Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF48CAE4), width: 2),
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.qr_code_scanner, size: 60, color: Color(0xFF48CAE4)),
                    const SizedBox(height: 12),
                    Text('Scanning...', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Point camera at QR code\nor enter code below',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Tap to stop scanning',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11))),
                  ]),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Tap to open camera',
                      style: GoogleFonts.poppins(fontSize: 14,
                          fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text('Scan customer QR code', style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
                ]),
          )),
        const SizedBox(height: 6),
        Text(
          'Note: On physical device, point camera at the QR code printed on the booking ticket.',
          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
        ),

        const SizedBox(height: 20),
        const SectionHeader('Or Enter QR Code Manually', icon: Icons.keyboard_outlined),
        WhiteCard(child: Column(children: [
          TextFormField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: 'QR Code (e.g. JAT-1234567890)',
              prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 22),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: () => _validate(_ctrl.text))),
            onFieldSubmitted: _validate,
            textInputAction: TextInputAction.done),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _processing ? null : () => _validate(_ctrl.text),
              icon: _processing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text('Validate & Mark Served', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A9396)))),
        ])),

        // Result
        if (_resultMsg != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _resultColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _resultColor.withOpacity(0.4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_resultIcon, color: _resultColor, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Text(_resultMsg!,
                    style: GoogleFonts.poppins(fontSize: 14,
                        fontWeight: FontWeight.w700, color: _resultColor))),
              ]),
              if (_found != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),
                _ir('Customer', _found!.name),
                _ir('Package',  _found!.packageName),
                _ir('Guests',   '${_found!.totalGuests}'),
                _ir('Phone',    _found!.phone),
                _ir('Amount',   'Rs.${_found!.totalAmount.toStringAsFixed(0)}'),
                _ir('Status',   _found!.canteenServed ? 'Served' : 'Pending'),
              ],
            ])),
        ],
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _ir(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text(l,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight))),
      Expanded(child: Text(v, style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
    ]));
}

// ══ All Customers Tab ══════════════════════════════════════════════════════
class _CustomerListTab extends StatefulWidget {
  final UserModel canteenUser;
  const _CustomerListTab({required this.canteenUser});
  @override State<_CustomerListTab> createState() => _CustomerListTabState();
}
class _CustomerListTabState extends State<_CustomerListTab> {
  DateTime _date = DateTime.now();
  List<CustomerModel> _all = [], _filtered = [];
  bool _loading = true;
  String _filter = 'all';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await StorageService.instance.getCustomersByDate(_date);
    _apply();
    setState(() => _loading = false);
  }

  void _apply() {
    setState(() {
      switch (_filter) {
        case 'served':    _filtered = _all.where((c) => c.canteenServed).toList(); break;
        case 'notserved': _filtered = _all.where((c) => !c.canteenServed).toList(); break;
        default:          _filtered = List.from(_all);
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime sel = _date;
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TableCalendar(firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: sel,
            selectedDayPredicate: (d) => sameDay(d, sel),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Color(0x5552B788), shape: BoxShape.circle)),
            onDaySelected: (s, _) => sel = s),
          ElevatedButton(
            onPressed: () { _date = sel; Navigator.pop(ctx); _load(); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            child: const Text('Apply')),
        ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(color: const Color(0xFF0A9396),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(children: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMMM yyyy').format(_date),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.edit_calendar_outlined, color: AppColors.textLight, size: 16),
              ]))),
          const SizedBox(height: 8),
          Row(children: [
            _fChip('All', 'all'), const SizedBox(width: 6),
            _fChip('Served', 'served'), const SizedBox(width: 6),
            _fChip('Not Served', 'notserved'),
          ]),
        ])),
      Container(color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('Total: ${_all.length}  ',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
          Container(width: 6, height: 6, decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle)),
          Text(' ${_all.where((c) => c.canteenServed).length} served  ',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success)),
          Container(width: 6, height: 6, decoration: const BoxDecoration(
              color: AppColors.warning, shape: BoxShape.circle)),
          Text(' ${_all.where((c) => !c.canteenServed).length} pending',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
        ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _filtered.isEmpty
            ? Center(child: Text('No customers',
                style: GoogleFonts.poppins(color: AppColors.textLight)))
            : RefreshIndicator(onRefresh: _load, color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _card(_filtered[i])))),
    ]);
  }

  Widget _card(CustomerModel c) {
    final served = c.canteenServed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (served ? AppColors.success : AppColors.warning).withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)]),
      child: Row(children: [
        CircleAvatar(radius: 20,
          backgroundColor: (served ? AppColors.success : AppColors.warning).withOpacity(0.12),
          child: Text(c.name[0].toUpperCase(), style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: served ? AppColors.success : AppColors.warning))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700)),
          Text(c.packageName, style: GoogleFonts.poppins(
              fontSize: 10, color: AppColors.textLight)),
          Text('${c.totalGuests} guests  •  Rs.${c.totalAmount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (served ? AppColors.success : AppColors.warning).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
          child: Text(served ? 'Served' : 'Pending', style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: served ? AppColors.success : AppColors.warning))),
      ]));
  }

  Widget _fChip(String label, String val) {
    final sel = _filter == val;
    return GestureDetector(
      onTap: () { _filter = val; _apply(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: sel ? const Color(0xFF0A9396) : Colors.white))));
  }
}
