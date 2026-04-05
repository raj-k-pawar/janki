import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManageCanteenScreen extends StatefulWidget {
  const ManageCanteenScreen({super.key});
  @override State<ManageCanteenScreen> createState() => _ManageCanteenScreenState();
}

class _ManageCanteenScreenState extends State<ManageCanteenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length:3,vsync:this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Canteen'),
        leading: IconButton(
            icon:const Icon(Icons.arrow_back_ios,color:Colors.white,size:18),
            onPressed:()=>Navigator.pop(context)),
        bottom: TabBar(controller:_tab,
          tabs:const [
            Tab(text:'Guests Served'),
            Tab(text:'Generate Payment'),
            Tab(text:'All Transactions'),
          ],
          indicatorColor:Colors.white, labelColor:Colors.white,
          unselectedLabelColor:Colors.white60,
          labelStyle:GoogleFonts.poppins(fontWeight:FontWeight.w600,fontSize:12)),
      ),
      body: TabBarView(controller:_tab, children:const [
        _GuestsServedTab(),
        _GeneratePaymentTab(),
        _AllTransactionsTab(),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 – Guests Served
// ══════════════════════════════════════════════════════════════════════════════
class _GuestsServedTab extends StatefulWidget {
  const _GuestsServedTab();
  @override State<_GuestsServedTab> createState() => _GuestsServedTabState();
}
class _GuestsServedTabState extends State<_GuestsServedTab> {
  DateTime _date = DateTime.now();
  List<CustomerModel> _all = [], _filtered = [];
  bool _loading = true;
  String _filter = 'all'; // all / served / notserved

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

  @override
  Widget build(BuildContext context) {
    return Column(children:[
      Container(color:AppColors.primary,
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
            _fChip('All','all'),
            const SizedBox(width:6),
            _fChip('Served','served'),
            const SizedBox(width:6),
            _fChip('Not Served','notserved'),
          ]),
        ])),
      // summary row
      Container(
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
        color:Colors.white,
        child:Row(children:[
          _sumBadge('Total',_all.length.toString(),AppColors.primary),
          const SizedBox(width:10),
          _sumBadge('Served',_all.where((c)=>c.canteenServed).length.toString(),AppColors.success),
          const SizedBox(width:10),
          _sumBadge('Pending',_all.where((c)=>!c.canteenServed).length.toString(),AppColors.warning),
        ])),
      Expanded(child:_loading
        ? const Center(child:CircularProgressIndicator(color:AppColors.primary))
        : _filtered.isEmpty
            ? Center(child:Text('No customers',style:GoogleFonts.poppins(color:AppColors.textLight)))
            : RefreshIndicator(onRefresh:_load,color:AppColors.primary,
                child:ListView.builder(
                  padding:const EdgeInsets.fromLTRB(14,8,14,20),
                  itemCount:_filtered.length,
                  itemBuilder:(_,i)=>_custCard(_filtered[i])))),
    ]);
  }

  Widget _custCard(CustomerModel c) {
    final served = c.canteenServed;
    return Container(
      margin:const EdgeInsets.only(bottom:8),
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:6)]),
      child:Row(children:[
        CircleAvatar(radius:20,
          backgroundColor:(served?AppColors.success:AppColors.warning).withOpacity(0.12),
          child:Text(c.name[0].toUpperCase(),style:GoogleFonts.poppins(
              fontSize:16,fontWeight:FontWeight.w700,
              color:served?AppColors.success:AppColors.warning))),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(c.name,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
          Text(c.packageName,style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
          Text('${c.totalGuests} guests  •  Rs.${c.totalAmount.toStringAsFixed(0)}',
              style:GoogleFonts.poppins(fontSize:11,color:AppColors.textMedium)),
        ])),
        Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
          decoration:BoxDecoration(
            color:(served?AppColors.success:AppColors.warning).withOpacity(0.12),
            borderRadius:BorderRadius.circular(20)),
          child:Text(served?'Served':'Pending',style:GoogleFonts.poppins(
              fontSize:11,fontWeight:FontWeight.w700,
              color:served?AppColors.success:AppColors.warning))),
      ]));
  }

  Widget _fChip(String label, String val) {
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
            color:sel?AppColors.primary:Colors.white))));
  }

  Widget _sumBadge(String l,String v,Color c) => Row(children:[
    Container(width:10,height:10,decoration:BoxDecoration(color:c,shape:BoxShape.circle)),
    const SizedBox(width:4),
    Text('$l: ',style:GoogleFonts.poppins(fontSize:12,color:AppColors.textLight)),
    Text(v,style:GoogleFonts.poppins(fontSize:12,fontWeight:FontWeight.w700,color:c)),
  ]);

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
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 – Generate Payment
// ══════════════════════════════════════════════════════════════════════════════
class _GeneratePaymentTab extends StatefulWidget {
  const _GeneratePaymentTab();
  @override State<_GeneratePaymentTab> createState() => _GeneratePaymentTabState();
}
class _GeneratePaymentTabState extends State<_GeneratePaymentTab> {
  final now = DateTime.now();
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;
  int _weekIdx = 0;
  List<_WeekRange> _weeks = [];
  int _servedCount = 0;
  double _totalAmt = 0;
  bool _loading = false;

  static const double _ratePerGuest = 80.0; // canteen rate per guest

  @override void initState() { super.initState(); _buildWeeks(); }

  void _buildWeeks() {
    _weeks = _getWeeks(_month, _year);
    if (_weekIdx >= _weeks.length) _weekIdx = 0;
    _calcStats();
  }

  Future<void> _calcStats() async {
    if (_weeks.isEmpty) return;
    setState(()=>_loading=true);
    final w = _weeks[_weekIdx];
    final all = await StorageService.instance.getCustomers();
    int cnt = 0;
    for (final c in all) {
      if (c.canteenServed &&
          !c.visitDate.isBefore(w.start) &&
          !c.visitDate.isAfter(w.end)) {
        cnt += c.totalGuests;
      }
    }
    setState((){
      _servedCount = cnt;
      _totalAmt = cnt * _ratePerGuest;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_weeks.isEmpty) return;
    final w = _weeks[_weekIdx];
    final tx = CanteenTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      month: _month, year: _year, weekNumber: _weekIdx+1,
      weekLabel: w.label,
      totalCustomers: _servedCount,
      amountPaid: _totalAmt,
      paidDate: DateTime.now(),
    );
    await StorageService.instance.addCanteenTransaction(tx);
    if (mounted) showSnack(context,'Payment saved!');
  }

  static List<_WeekRange> _getWeeks(int month, int year) {
    final weeks = <_WeekRange>[];
    DateTime cur = DateTime(year, month, 1);
    final lastDay = DateTime(year, month+1, 0);
    final fmt = DateFormat('dd MMM');
    while (!cur.isAfter(lastDay)) {
      final end = cur.add(const Duration(days:6));
      final wEnd = end.isAfter(lastDay) ? lastDay : end;
      weeks.add(_WeekRange(cur, wEnd,
          '${fmt.format(cur)} – ${fmt.format(wEnd)}'));
      cur = wEnd.add(const Duration(days:1));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return SingleChildScrollView(
      padding:const EdgeInsets.all(16),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const SectionHeader('Select Month & Week',icon:Icons.date_range_outlined),
        WhiteCard(child:Column(children:[
          Row(children:[
            Expanded(child:DropdownButtonFormField<int>(
              value:_month,
              items:List.generate(12,(i)=>DropdownMenuItem(
                  value:i+1,child:Text(months[i+1]))),
              onChanged:(v){if(v!=null){setState(()=>_month=v);_buildWeeks();}},
              decoration:const InputDecoration(labelText:'Month'))),
            const SizedBox(width:10),
            Expanded(child:DropdownButtonFormField<int>(
              value:_year,
              items:[2024,2025,2026,2027].map((y)=>DropdownMenuItem(
                  value:y,child:Text('$y'))).toList(),
              onChanged:(v){if(v!=null){setState(()=>_year=v);_buildWeeks();}},
              decoration:const InputDecoration(labelText:'Year'))),
          ]),
          const SizedBox(height:12),
          if(_weeks.isNotEmpty)
            DropdownButtonFormField<int>(
              value:_weekIdx,
              items:List.generate(_weeks.length,(i)=>DropdownMenuItem(
                  value:i,child:Text('Week ${i+1}: ${_weeks[i].label}'))),
              onChanged:(v){if(v!=null){setState(()=>_weekIdx=v);_calcStats();}},
              decoration:const InputDecoration(labelText:'Select Week')),
        ])),

        const SectionHeader('Canteen Payment Summary',icon:Icons.summarize_outlined),
        Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
              colors:[AppColors.primaryDark,AppColors.primary],
              begin:Alignment.topLeft,end:Alignment.bottomRight),
            borderRadius:BorderRadius.circular(16),
            boxShadow:[BoxShadow(color:AppColors.primary.withOpacity(0.35),
                blurRadius:12,offset:const Offset(0,6))]),
          child:_loading
            ? const Center(child:CircularProgressIndicator(color:Colors.white))
            : Column(children:[
                _sRow('Week',_weeks.isNotEmpty?_weeks[_weekIdx].label:'–'),
                _sRow('Total Served Guests','$_servedCount guests'),
                _sRow('Rate Per Guest','Rs.${_ratePerGuest.toStringAsFixed(0)}'),
                const Divider(color:Colors.white30,height:16),
                Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                  Text('Total Amount',style:GoogleFonts.poppins(
                      fontSize:14,fontWeight:FontWeight.w600,color:Colors.white70)),
                  Text('Rs.${_totalAmt.toStringAsFixed(0)}',style:GoogleFonts.poppins(
                      fontSize:26,fontWeight:FontWeight.w700,color:Colors.white)),
                ]),
              ])),
        const SizedBox(height:20),
        PrimaryButton(label:'Save Payment',icon:Icons.save_outlined,onTap:_save),
        const SizedBox(height:30),
      ]));
  }

  Widget _sRow(String l,String v) => Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(l,style:GoogleFonts.poppins(fontSize:13,color:Colors.white70)),
      Text(v,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w600,color:Colors.white)),
    ]));
}

class _WeekRange {
  final DateTime start, end;
  final String label;
  _WeekRange(this.start,this.end,this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 – All Transactions
// ══════════════════════════════════════════════════════════════════════════════
class _AllTransactionsTab extends StatefulWidget {
  const _AllTransactionsTab();
  @override State<_AllTransactionsTab> createState() => _AllTransactionsTabState();
}
class _AllTransactionsTabState extends State<_AllTransactionsTab> {
  List<CanteenTransaction> _txns = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(()=>_loading=true);
    _txns = await StorageService.instance.getCanteenTransactions();
    setState(()=>_loading=false);
  }

  @override
  Widget build(BuildContext context) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return _loading
        ? const Center(child:CircularProgressIndicator(color:AppColors.primary))
        : _txns.isEmpty
            ? Center(child:Text('No transactions yet',
                style:GoogleFonts.poppins(color:AppColors.textLight)))
            : RefreshIndicator(
                onRefresh:_load, color:AppColors.primary,
                child:ListView.builder(
                  padding:const EdgeInsets.all(14),
                  itemCount:_txns.length,
                  itemBuilder:(_,i){
                    final t=_txns[i];
                    return Container(
                      margin:const EdgeInsets.only(bottom:10),
                      padding:const EdgeInsets.all(14),
                      decoration:BoxDecoration(color:Colors.white,
                          borderRadius:BorderRadius.circular(12),
                          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),
                              blurRadius:6,offset:const Offset(0,2))]),
                      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Row(children:[
                          Expanded(child:Text('${months[t.month]} ${t.year} – Week ${t.weekNumber}',
                              style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700,
                                  color:AppColors.textDark))),
                          Text('Rs.${t.amountPaid.toStringAsFixed(0)}',
                              style:GoogleFonts.poppins(fontSize:15,fontWeight:FontWeight.w700,
                                  color:AppColors.primary)),
                        ]),
                        const SizedBox(height:4),
                        Text(t.weekLabel,style:GoogleFonts.poppins(
                            fontSize:11,color:AppColors.textLight)),
                        const SizedBox(height:6),
                        Row(children:[
                          _chip('${t.totalCustomers} guests',AppColors.primary),
                          const SizedBox(width:6),
                          _chip(DateFormat('dd MMM').format(t.paidDate),AppColors.textLight),
                        ]),
                      ]));
                  }));
  }

  Widget _chip(String t,Color c) => Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:3),
    decoration:BoxDecoration(color:c.withOpacity(0.1),borderRadius:BorderRadius.circular(6)),
    child:Text(t,style:GoogleFonts.poppins(fontSize:11,fontWeight:FontWeight.w600,color:c)));
}
