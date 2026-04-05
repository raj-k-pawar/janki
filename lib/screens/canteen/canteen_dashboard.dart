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
  @override void initState() { super.initState(); _tab=TabController(length:2,vsync:this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4D6E), Color(0xFF0A9396), Color(0xFF48CAE4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(bottom:false, child: Column(children:[
            Padding(padding:const EdgeInsets.fromLTRB(20,14,20,0),
              child:Row(children:[
                Container(width:46,height:46,
                  decoration:BoxDecoration(color:Colors.white24,
                      borderRadius:BorderRadius.circular(13)),
                  child:Center(child:Text(widget.user.fullName[0].toUpperCase(),
                      style:GoogleFonts.poppins(fontSize:20,fontWeight:FontWeight.w700,
                          color:Colors.white)))),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('Canteen Dashboard',style:GoogleFonts.poppins(fontSize:11,color:Colors.white70)),
                  Text(widget.user.fullName,style:GoogleFonts.poppins(
                      fontSize:15,fontWeight:FontWeight.w700,color:Colors.white)),
                ])),
                GestureDetector(
                  onTap:()async{
                    await StorageService.instance.logout();
                    if(!mounted) return;
                    Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);
                  },
                  child:Container(padding:const EdgeInsets.all(8),
                    decoration:BoxDecoration(color:Colors.white24,
                        borderRadius:BorderRadius.circular(10)),
                    child:const Icon(Icons.logout,color:Colors.white,size:20))),
              ])),
            TabBar(controller:_tab,
              tabs:const [Tab(text:'All Customers'), Tab(text:'Scan QR Code')],
              indicatorColor:Colors.white, labelColor:Colors.white,
              unselectedLabelColor:Colors.white60,
              labelStyle:GoogleFonts.poppins(fontWeight:FontWeight.w600)),
          ])),
        ),
        Expanded(child:TabBarView(controller:_tab, children:[
          _CustomerListTab(canteenUser:widget.user),
          _ScanQrTab(canteenUser:widget.user),
        ])),
      ]),
    );
  }
}

// ── All Customers Tab ─────────────────────────────────────────────────────
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
    setState(()=>_loading=true);
    _all = await StorageService.instance.getCustomersByDate(_date);
    _apply();
    setState(()=>_loading=false);
  }

  void _apply() {
    setState((){
      switch(_filter){
        case 'served':    _filtered=_all.where((c)=>c.canteenServed).toList(); break;
        case 'notserved': _filtered=_all.where((c)=>!c.canteenServed).toList(); break;
        default:          _filtered=List.from(_all);
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime sel=_date;
    await showDialog(context:context,builder:(ctx)=>Dialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
      child:Padding(padding:const EdgeInsets.all(14),child:Column(mainAxisSize:MainAxisSize.min,children:[
        TableCalendar(firstDay:DateTime(2020),lastDay:DateTime(2030),focusedDay:sel,
          selectedDayPredicate:(d)=>sameDay(d,sel),calendarFormat:CalendarFormat.month,
          headerStyle:const HeaderStyle(formatButtonVisible:false,titleCentered:true),
          calendarStyle:const CalendarStyle(
            selectedDecoration:BoxDecoration(color:AppColors.primary,shape:BoxShape.circle),
            todayDecoration:BoxDecoration(color:Color(0x5552B788),shape:BoxShape.circle)),
          onDaySelected:(s,_){sel=s;}),
        ElevatedButton(onPressed:(){_date=sel;Navigator.pop(ctx);_load();},
          style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,44)),
          child:const Text('Apply')),
      ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children:[
      Container(color:const Color(0xFF0A9396),
        padding:const EdgeInsets.fromLTRB(14,8,14,12),
        child:Column(children:[
          GestureDetector(
            onTap:_pickDate,
            child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10)),
              child:Row(children:[
                const Icon(Icons.calendar_today,color:AppColors.primary,size:16),
                const SizedBox(width:8),
                Text(DateFormat('dd MMMM yyyy').format(_date),
                    style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.edit_calendar_outlined,color:AppColors.textLight,size:16),
              ]))),
          const SizedBox(height:8),
          Row(children:[
            _fc('All','all'),
            const SizedBox(width:6),
            _fc('Served','served'),
            const SizedBox(width:6),
            _fc('Not Served','notserved'),
          ]),
        ])),
      // Stats row
      Container(color:Colors.white,
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
        child:Row(children:[
          Text('Total: ${_all.length}  ',style:GoogleFonts.poppins(
              fontSize:12,color:AppColors.textMedium)),
          Container(width:6,height:6,decoration:const BoxDecoration(
              color:AppColors.success,shape:BoxShape.circle)),
          Text(' Served: ${_all.where((c)=>c.canteenServed).length}  ',
              style:GoogleFonts.poppins(fontSize:12,color:AppColors.success)),
          Container(width:6,height:6,decoration:const BoxDecoration(
              color:AppColors.warning,shape:BoxShape.circle)),
          Text(' Pending: ${_all.where((c)=>!c.canteenServed).length}',
              style:GoogleFonts.poppins(fontSize:12,color:AppColors.warning)),
        ])),
      Expanded(child:_loading
        ? const Center(child:CircularProgressIndicator(color:AppColors.primary))
        : _filtered.isEmpty
            ? Center(child:Text('No customers',style:GoogleFonts.poppins(color:AppColors.textLight)))
            : RefreshIndicator(onRefresh:_load,color:AppColors.primary,
                child:ListView.builder(
                  padding:const EdgeInsets.fromLTRB(14,8,14,20),
                  itemCount:_filtered.length,
                  itemBuilder:(_,i)=>_card(_filtered[i])))),
    ]);
  }

  Widget _card(CustomerModel c) {
    final served=c.canteenServed;
    return Container(
      margin:const EdgeInsets.only(bottom:8),
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
          border:Border.all(color:(served?AppColors.success:AppColors.warning).withOpacity(0.25)),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04),blurRadius:5)]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          CircleAvatar(radius:18,
            backgroundColor:(served?AppColors.success:AppColors.warning).withOpacity(0.12),
            child:Text(c.name[0].toUpperCase(),style:GoogleFonts.poppins(
                fontSize:14,fontWeight:FontWeight.w700,
                color:served?AppColors.success:AppColors.warning))),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(c.name,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
            Text('${c.phone}  •  ${c.city}',style:GoogleFonts.poppins(
                fontSize:10,color:AppColors.textLight)),
          ])),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
            decoration:BoxDecoration(
              color:(served?AppColors.success:AppColors.warning).withOpacity(0.1),
              borderRadius:BorderRadius.circular(20)),
            child:Text(served?'Served':'Pending',style:GoogleFonts.poppins(
                fontSize:11,fontWeight:FontWeight.w700,
                color:served?AppColors.success:AppColors.warning))),
        ]),
        const SizedBox(height:8),
        Container(
          padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),
          decoration:BoxDecoration(color:AppColors.primary.withOpacity(0.07),
              borderRadius:BorderRadius.circular(6)),
          child:Text(c.packageName,style:GoogleFonts.poppins(
              fontSize:10,color:AppColors.primary,fontWeight:FontWeight.w500))),
        const SizedBox(height:6),
        Row(children:[
          Text('${c.totalGuests} guests',
              style:GoogleFonts.poppins(fontSize:11,color:AppColors.textMedium)),
          const Spacer(),
          Text('QR: ${c.qrCode}',
              style:GoogleFonts.poppins(fontSize:10,color:AppColors.textLight,
                  letterSpacing:0.5)),
        ]),
      ]));
  }

  Widget _fc(String label,String val){
    final sel=_filter==val;
    return GestureDetector(
      onTap:(){_filter=val;_apply();},
      child:Container(
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
        decoration:BoxDecoration(
          color:sel?Colors.white:Colors.white24,
          borderRadius:BorderRadius.circular(20)),
        child:Text(label,style:GoogleFonts.poppins(
            fontSize:11,fontWeight:FontWeight.w600,
            color:sel?const Color(0xFF0A9396):Colors.white))));
  }
}

// ── Scan QR Tab ───────────────────────────────────────────────────────────
class _ScanQrTab extends StatefulWidget {
  final UserModel canteenUser;
  const _ScanQrTab({required this.canteenUser});
  @override State<_ScanQrTab> createState() => _ScanQrTabState();
}
class _ScanQrTabState extends State<_ScanQrTab> {
  final _ctrl = TextEditingController();
  String? _status;
  Color  _statusColor = AppColors.textDark;
  CustomerModel? _lastCustomer;
  bool _processing = false;

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _validate(String code) async {
    if (code.trim().isEmpty) return;
    setState(()=>_processing=true);
    final trimmed = code.trim();
    final all = await StorageService.instance.getCustomers();
    final today = DateTime.now();

    CustomerModel? found;
    for (final c in all) {
      if (c.qrCode == trimmed) { found = c; break; }
    }

    if (found == null) {
      setState((){
        _status = 'QR code not found. Invalid code.';
        _statusColor = AppColors.error;
        _lastCustomer = null;
        _processing = false;
      });
      return;
    }

    // Check if valid for today
    final isToday = sameDay(found.visitDate, today);
    if (!isToday) {
      setState((){
        _status = 'QR code is not valid for today.\nBooked for: ${DateFormat('dd MMM yyyy').format(found!.visitDate)}';
        _statusColor = AppColors.warning;
        _lastCustomer = found;
        _processing = false;
      });
      return;
    }

    if (found.canteenServed) {
      setState((){
        _status = 'Already served! This QR was already used.';
        _statusColor = AppColors.warning;
        _lastCustomer = found;
        _processing = false;
      });
      return;
    }

    // Mark as served
    await StorageService.instance.markCanteenServed(found.id);
    setState((){
      _status = 'Valid QR! Marked as SERVED.';
      _statusColor = AppColors.success;
      _lastCustomer = found;
      _processing = false;
    });
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const SectionHeader('Scan / Enter QR Code',icon:Icons.qr_code_scanner),
        WhiteCard(child:Column(children:[
          Container(
            padding:const EdgeInsets.all(20),
            decoration:BoxDecoration(
              color:const Color(0xFF0A9396).withOpacity(0.06),
              borderRadius:BorderRadius.circular(12),
              border:Border.all(color:const Color(0xFF0A9396).withOpacity(0.2))),
            child:Column(children:[
              const Icon(Icons.qr_code_scanner,size:60,color:Color(0xFF0A9396)),
              const SizedBox(height:10),
              Text('Scan customer QR code or enter manually below',
                  style:GoogleFonts.poppins(fontSize:12,color:AppColors.textMedium),
                  textAlign:TextAlign.center),
            ])),
          const SizedBox(height:16),
          TextFormField(
            controller:_ctrl,
            decoration:InputDecoration(
              labelText:'Enter QR Code (e.g. JAT-1234567890)',
              prefixIcon:const Icon(Icons.qr_code_2,color:AppColors.primary,size:22),
              suffixIcon:IconButton(
                icon:const Icon(Icons.send,color:AppColors.primary),
                onPressed:()=>_validate(_ctrl.text))),
            onFieldSubmitted:_validate),
          const SizedBox(height:14),
          SizedBox(width:double.infinity,height:50,
            child:ElevatedButton.icon(
              onPressed:_processing?null:()=>_validate(_ctrl.text),
              icon:_processing
                ? const SizedBox(width:18,height:18,
                    child:CircularProgressIndicator(color:Colors.white,strokeWidth:2))
                : const Icon(Icons.check_circle_outline,color:Colors.white),
              label:Text('Validate QR Code',style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w600,color:Colors.white)),
              style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF0A9396)))),
        ])),

        if (_status != null) ...[
          const SizedBox(height:6),
          Container(
            width:double.infinity,
            padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(
              color:_statusColor.withOpacity(0.1),
              borderRadius:BorderRadius.circular(14),
              border:Border.all(color:_statusColor.withOpacity(0.4))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Icon(
                  _statusColor == AppColors.success
                      ? Icons.check_circle_outline
                      : _statusColor == AppColors.error
                          ? Icons.cancel_outlined
                          : Icons.warning_amber_outlined,
                  color:_statusColor, size:24),
                const SizedBox(width:10),
                Expanded(child:Text(_status!,style:GoogleFonts.poppins(
                    fontSize:14,fontWeight:FontWeight.w700,color:_statusColor))),
              ]),
              if (_lastCustomer != null) ...[
                const SizedBox(height:10),
                const Divider(),
                const SizedBox(height:6),
                _infoRow('Customer',_lastCustomer!.name),
                _infoRow('Package', _lastCustomer!.packageName),
                _infoRow('Guests',  '${_lastCustomer!.totalGuests}'),
                _infoRow('Phone',   _lastCustomer!.phone),
                _infoRow('Status',
                    _lastCustomer!.canteenServed ? 'Served' : 'Pending'),
              ],
            ])),
        ],
        const SizedBox(height:30),
      ]));
  }

  Widget _infoRow(String l,String v) => Padding(
    padding:const EdgeInsets.symmetric(vertical:3),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(width:80,child:Text(l,style:GoogleFonts.poppins(
          fontSize:12,color:AppColors.textLight))),
      Expanded(child:Text(v,style:GoogleFonts.poppins(
          fontSize:12,fontWeight:FontWeight.w600,color:AppColors.textDark))),
    ]));
}
