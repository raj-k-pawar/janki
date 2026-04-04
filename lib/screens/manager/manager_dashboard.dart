import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';
import 'add_customer_screen.dart';
import 'all_customers_screen.dart';
import 'manage_workers_screen.dart';
import 'enquiry_screen.dart';

class ManagerDashboard extends StatefulWidget {
  final UserModel user;
  const ManagerDashboard({super.key, required this.user});
  @override State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  DateTime _selectedDate = DateTime.now();
  List<CustomerModel> _customers = [];
  bool _loading = true;
  bool _calendarExpanded = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _customers = await StorageService.instance.getCustomersByDate(_selectedDate);
    setState(() => _loading = false);
  }

  // ── stats ──
  int    get _totalBookings  => _customers.length;
  int    get _totalGuests    => _customers.fold(0, (s,c) => s + c.totalGuests);
  double get _totalCash      => _customers.where((c) => c.paymentMode==PaymentMode.cash)
                                          .fold(0.0,(s,c)=>s+c.totalAmount);
  double get _totalOnline    => _customers.where((c) => c.paymentMode==PaymentMode.online)
                                          .fold(0.0,(s,c)=>s+c.totalAmount);
  double get _totalAmount    => _totalCash + _totalOnline;

  // Batch-wise
  int _batchGuests(bool Function(CustomerModel) filter) =>
      _customers.where(filter).fold(0, (s,c) => s + c.totalGuests);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final dateLabel = sameDay(_selectedDate, DateTime.now())
        ? 'Today – ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
        : DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar toggle
                  GestureDetector(
                    onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color:Colors.black12, blurRadius:6, offset:const Offset(0,2))],
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color:AppColors.primary, size:20),
                        const SizedBox(width:10),
                        Expanded(child: Text(dateLabel, style:GoogleFonts.poppins(
                            fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textDark))),
                        Icon(_calendarExpanded ? Icons.expand_less : Icons.expand_more,
                            color:AppColors.primary),
                      ]),
                    ),
                  ),
                  if (_calendarExpanded) ...[
                    const SizedBox(height:8),
                    Container(
                      decoration: BoxDecoration(color:Colors.white,
                          borderRadius:BorderRadius.circular(14)),
                      child: TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        focusedDay: _selectedDate,
                        selectedDayPredicate: (d) => sameDay(d, _selectedDate),
                        calendarFormat: CalendarFormat.month,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: GoogleFonts.poppins(
                              fontWeight:FontWeight.w700, fontSize:14)),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                              color:AppColors.primary, shape:BoxShape.circle),
                          todayDecoration: BoxDecoration(
                              color:AppColors.primaryLight.withOpacity(0.4),
                              shape:BoxShape.circle),
                          todayTextStyle: const TextStyle(color:AppColors.primaryDark),
                        ),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDate = selected;
                            _calendarExpanded = false;
                          });
                          _load();
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height:16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(color:AppColors.primary))
                  else ...[
                    // Transaction Details
                    const SectionHeader('Transaction Details', icon: Icons.receipt_long_outlined),
                    WhiteCard(child: Column(children:[
                      _txRow('Total Bookings',  '$_totalBookings'),
                      _txRow('Total Guests',    '$_totalGuests'),
                      _txRow('Cash Amount',     '₹${fmt.format(_totalCash)}'),
                      _txRow('Online Amount',   '₹${fmt.format(_totalOnline)}'),
                      const Divider(height:16),
                      _txRow('Total Amount', '₹${fmt.format(_totalAmount)}', bold:true),
                    ])),

                    // Batch wise
                    const SectionHeader('Batch Wise', icon: Icons.group_outlined),
                    WhiteCard(child: Column(children:[
                      _txRow('Morning Batch Guests',
                          '${_batchGuests((c) => c.packageName.contains('सकाळी') && !c.packageName.contains('निवासी'))}'),
                      _txRow('Evening Batch Guests',
                          '${_batchGuests((c) => c.packageName.contains('सायंकाळी') && !c.packageName.contains('निवासी'))}'),
                      _txRow('Full Day Guests',
                          '${_batchGuests((c) => c.packageName.contains('फुल डे'))}'),
                      _txRow('Stay Customers',
                          '${_batchGuests((c) => c.packageName.contains('निवासी'))}'),
                    ])),
                  ],

                  const SizedBox(height:8),
                  Text('Quick Actions', style:GoogleFonts.poppins(
                      fontSize:15, fontWeight:FontWeight.w700, color:AppColors.textDark)),
                  const SizedBox(height:10),

                  ActionTile(label:'Add New Customer', subtitle:'Register a new booking',
                    icon:Icons.person_add_outlined, color:AppColors.primary,
                    onTap:() async {
                      await Navigator.push(context, MaterialPageRoute(
                          builder:(_)=>AddCustomerScreen(managerUser:widget.user)));
                      _load();
                    }),
                  ActionTile(label:'View All Customers', subtitle:'Browse & manage bookings',
                    icon:Icons.people_outline, color:AppColors.cardBlue,
                    onTap:()=>Navigator.push(context,
                        MaterialPageRoute(builder:(_)=>const AllCustomersScreen()))),
                  ActionTile(label:'Manage Workers', subtitle:'Attendance & staff',
                    icon:Icons.badge_outlined, color:AppColors.cardTeal,
                    onTap:()=>Navigator.push(context,
                        MaterialPageRoute(builder:(_)=>const ManageWorkersScreen(ownerMode:false)))),
                  ActionTile(label:'Add Enquiry', subtitle:'Record visitor enquiry',
                    icon:Icons.contact_phone_outlined, color:AppColors.cardOrange,
                    onTap:()=>Navigator.push(context,
                        MaterialPageRoute(builder:(_)=>const EnquiryScreen()))),

                  const SizedBox(height:30),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greet = hour<12 ? '🌅 Good Morning' : hour<17 ? '☀️ Good Afternoon' : '🌙 Good Evening';
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left:20, right:20, bottom:20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors:[AppColors.primaryDark, AppColors.primary, Color(0xFF52B788)],
          begin:Alignment.topLeft, end:Alignment.bottomRight,
        ),
      ),
      child: Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(greet, style:GoogleFonts.poppins(color:Colors.white70, fontSize:12)),
          Text(widget.user.fullName, style:GoogleFonts.poppins(
              fontSize:18, fontWeight:FontWeight.w700, color:Colors.white)),
          Container(
            margin:const EdgeInsets.only(top:4),
            padding:const EdgeInsets.symmetric(horizontal:10, vertical:3),
            decoration:BoxDecoration(
                color:AppColors.accent.withOpacity(0.85),
                borderRadius:BorderRadius.circular(20)),
            child:Text('🌿 ${widget.user.roleLabel}',style:GoogleFonts.poppins(
                fontSize:11, fontWeight:FontWeight.w600, color:Colors.white)),
          ),
        ])),
        GestureDetector(
          onTap:() async {
            await StorageService.instance.logout();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder:(_)=>const LoginScreen()), (_)=>false);
          },
          child:Container(
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
            decoration:BoxDecoration(color:Colors.white24,
                borderRadius:BorderRadius.circular(8)),
            child:Row(children:[
              const Icon(Icons.logout, color:Colors.white, size:14),
              const SizedBox(width:4),
              Text('Logout',style:GoogleFonts.poppins(color:Colors.white,fontSize:12)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _txRow(String label, String value, {bool bold=false}) => Padding(
    padding:const EdgeInsets.symmetric(vertical:5),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
      Text(label, style:GoogleFonts.poppins(fontSize:13, color:AppColors.textMedium)),
      Text(value, style:GoogleFonts.poppins(fontSize:13,
          fontWeight: bold?FontWeight.w700:FontWeight.w600,
          color: bold?AppColors.primary:AppColors.textDark)),
    ]),
  );
}
