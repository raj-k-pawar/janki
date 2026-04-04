import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';
import '../manager/all_customers_screen.dart';
import '../manager/manage_workers_screen.dart';
import 'manage_packages_screen.dart';

class OwnerDashboard extends StatefulWidget {
  final UserModel user;
  const OwnerDashboard({super.key, required this.user});
  @override State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  DateTime _selectedDate = DateTime.now();
  List<CustomerModel> _customers = [];
  List<UserModel>     _managers  = [];
  bool _loading = true, _calExpanded = false;

  @override void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    setState(()=>_loading=true);
    _customers = await StorageService.instance.getCustomersByDate(_selectedDate);
    _managers  = await StorageService.instance.getAllManagers();
    setState(()=>_loading=false);
  }

  int    get _totalBookings => _customers.length;
  int    get _totalGuests   => _customers.fold(0,(s,c)=>s+c.totalGuests);
  double get _cashAmt       => _customers.where((c)=>c.paymentMode==PaymentMode.cash).fold(0.0,(s,c)=>s+c.totalAmount);
  double get _onlineAmt     => _customers.where((c)=>c.paymentMode==PaymentMode.online).fold(0.0,(s,c)=>s+c.totalAmount);
  double get _totalAmt      => _cashAmt + _onlineAmt;

  @override
  Widget build(BuildContext context){
    final fmt = NumberFormat('#,##,###','en_IN');
    final dateLabel = sameDay(_selectedDate,DateTime.now())
        ? 'Today – ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
        : DateFormat('dd MMM yyyy').format(_selectedDate);
    return Scaffold(
      backgroundColor:AppColors.background,
      body:RefreshIndicator(onRefresh:_load, color:AppColors.primary,
        child:CustomScrollView(slivers:[
          SliverToBoxAdapter(child:_header()),
          SliverToBoxAdapter(child:Padding(
            padding:const EdgeInsets.all(16),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              // Calendar toggle
              GestureDetector(onTap:()=>setState(()=>_calExpanded=!_calExpanded),
                child:Container(
                  padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                      boxShadow:[const BoxShadow(color:Colors.black12,blurRadius:6,offset:Offset(0,2))]),
                  child:Row(children:[
                    const Icon(Icons.calendar_today,color:AppColors.primary,size:20),
                    const SizedBox(width:10),
                    Expanded(child:Text(dateLabel,style:GoogleFonts.poppins(
                        fontSize:13,fontWeight:FontWeight.w600))),
                    Icon(_calExpanded?Icons.expand_less:Icons.expand_more,color:AppColors.primary),
                  ]))),
              if(_calExpanded)...[
                const SizedBox(height:8),
                Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14)),
                  child:TableCalendar(
                    firstDay:DateTime(2020),lastDay:DateTime(2030),focusedDay:_selectedDate,
                    selectedDayPredicate:(d)=>sameDay(d,_selectedDate),
                    calendarFormat:CalendarFormat.month,
                    headerStyle:HeaderStyle(formatButtonVisible:false,titleCentered:true,
                        titleTextStyle:GoogleFonts.poppins(fontWeight:FontWeight.w700,fontSize:14)),
                    calendarStyle:const CalendarStyle(
                      selectedDecoration:BoxDecoration(color:AppColors.primary,shape:BoxShape.circle),
                      todayDecoration:BoxDecoration(color:Color(0xFF52B78844),shape:BoxShape.circle),
                      todayTextStyle:TextStyle(color:AppColors.primaryDark)),
                    onDaySelected:(sel,_){
                      setState((){_selectedDate=sel;_calExpanded=false;});
                      _load();
                    })),
              ],
              const SizedBox(height:16),
              if(_loading)
                const Center(child:CircularProgressIndicator(color:AppColors.primary))
              else...[
                const SectionHeader('Transaction Details',icon:Icons.receipt_long_outlined),
                WhiteCard(child:Column(children:[
                  _row('Total Bookings','$_totalBookings'),
                  _row('Total Guests',  '$_totalGuests'),
                  _row('Cash Amount',   '₹${fmt.format(_cashAmt)}'),
                  _row('Online Amount', '₹${fmt.format(_onlineAmt)}'),
                  const Divider(height:14),
                  _row('Total Amount',  '₹${fmt.format(_totalAmt)}',bold:true),
                ])),
                const SectionHeader('Batch Wise',icon:Icons.group_outlined),
                WhiteCard(child:Column(children:[
                  _row('Morning Batch','${_customers.where((c)=>c.packageName.contains('सकाळी')&&!c.packageName.contains('निवासी')).fold(0,(s,c)=>s+c.totalGuests)}'),
                  _row('Evening Batch','${_customers.where((c)=>c.packageName.contains('सायंकाळी')&&!c.packageName.contains('निवासी')).fold(0,(s,c)=>s+c.totalGuests)}'),
                  _row('Full Day',    '${_customers.where((c)=>c.packageName.contains('फुल डे')).fold(0,(s,c)=>s+c.totalGuests)}'),
                  _row('Stay Customers','${_customers.where((c)=>c.packageName.contains('निवासी')).fold(0,(s,c)=>s+c.totalGuests)}'),
                ])),
                const SectionHeader('Manager Wise',icon:Icons.manage_accounts_outlined),
                WhiteCard(child:Column(children:_managers.isEmpty
                    ? [Text('No managers',style:GoogleFonts.poppins())]
                    : _managers.map((m){
                        final cnt=_customers.where((c)=>c.managerId==m.id).length;
                        return _row(m.fullName,'$cnt bookings');
                      }).toList())),
              ],
              const SizedBox(height:8),
              Text('Quick Actions',style:GoogleFonts.poppins(fontSize:15,fontWeight:FontWeight.w700)),
              const SizedBox(height:10),
              ActionTile(label:'View All Customers',subtitle:'Browse all bookings',
                icon:Icons.people_outline,color:AppColors.cardBlue,
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AllCustomersScreen()))),
              ActionTile(label:'Manage Workers',subtitle:'Add staff, salary, attendance',
                icon:Icons.badge_outlined,color:AppColors.cardTeal,
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ManageWorkersScreen(ownerMode:true)))),
              ActionTile(label:'Manage Packages',subtitle:'Add / edit packages & pricing',
                icon:Icons.category_outlined,color:AppColors.cardPurple,
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ManagePackagesScreen()))),
              const SizedBox(height:30),
            ]),
          )),
        ])),
    );
  }

  Widget _header(){
    return Container(
      padding:EdgeInsets.only(top:MediaQuery.of(context).padding.top+16,
          left:20,right:20,bottom:20),
      decoration:const BoxDecoration(
        gradient:LinearGradient(
          colors:[Color(0xFF6A0572),Color(0xFF9B2FB5),Color(0xFFBB6BD9)],
          begin:Alignment.topLeft,end:Alignment.bottomRight)),
      child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Owner Dashboard',style:GoogleFonts.poppins(color:Colors.white70,fontSize:12)),
          Text(widget.user.fullName,style:GoogleFonts.poppins(
              fontSize:18,fontWeight:FontWeight.w700,color:Colors.white)),
          Container(margin:const EdgeInsets.only(top:4),
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
            decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(20)),
            child:Text('👑 ${widget.user.roleLabel}',style:GoogleFonts.poppins(
                fontSize:11,fontWeight:FontWeight.w600,color:Colors.white))),
        ])),
        GestureDetector(onTap:() async {
          await StorageService.instance.logout();
          if(!mounted) return;
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);
        },
          child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
            decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(8)),
            child:Row(children:[
              const Icon(Icons.logout,color:Colors.white,size:14),
              const SizedBox(width:4),
              Text('Logout',style:GoogleFonts.poppins(color:Colors.white,fontSize:12)),
            ]))),
      ]),
    );
  }

  Widget _row(String l,String v,{bool bold=false})=>Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(l,style:GoogleFonts.poppins(fontSize:13,color:AppColors.textMedium)),
      Text(v,style:GoogleFonts.poppins(fontSize:13,
          fontWeight:bold?FontWeight.w700:FontWeight.w600,
          color:bold?AppColors.primary:AppColors.textDark)),
    ]));
}
