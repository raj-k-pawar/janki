import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManageWorkersScreen extends StatefulWidget {
  final bool ownerMode;
  const ManageWorkersScreen({super.key, this.ownerMode=false});
  @override State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}
class _ManageWorkersScreenState extends State<ManageWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<WorkerModel> _workers=[];
  List<AdvancePayment> _advances=[];
  List<SalaryPayment> _salaries=[];
  bool _loading=true;
  DateTime _attendanceDate = DateTime.now();
  Map<String,bool> _todayAttendance={};

  @override void initState(){
    super.initState();
    _tab=TabController(length: widget.ownerMode?3:1, vsync:this);
    _load();
  }
  @override void dispose(){ _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(()=>_loading=true);
    _workers  = await StorageService.instance.getWorkers();
    _advances = await StorageService.instance.getAdvances();
    _salaries = await StorageService.instance.getSalaries();
    for(final w in _workers){
      _todayAttendance[w.id] = await StorageService.instance
          .getWorkerAttendance(w.id, _attendanceDate);
    }
    setState(()=>_loading=false);
  }

  @override
  Widget build(BuildContext context){
    final tabs = widget.ownerMode
        ? const [Tab(text:'Workers'), Tab(text:'Advance'), Tab(text:'Salary')]
        : const [Tab(text:'Attendance')];
    return Scaffold(
      backgroundColor:AppColors.background,
      appBar:AppBar(
        title:const Text('Manage Workers'),
        leading:IconButton(icon:const Icon(Icons.arrow_back_ios,color:Colors.white,size:18),
            onPressed:()=>Navigator.pop(context)),
        bottom:TabBar(controller:_tab, tabs:tabs,
            indicatorColor:Colors.white, labelColor:Colors.white,
            unselectedLabelColor:Colors.white60,
            labelStyle:GoogleFonts.poppins(fontWeight:FontWeight.w600)),
        actions:[
          if(widget.ownerMode) IconButton(
            icon:const Icon(Icons.person_add_outlined,color:Colors.white),
            onPressed:_showAddWorker),
          IconButton(icon:const Icon(Icons.refresh,color:Colors.white),onPressed:_load),
        ],
      ),
      body:_loading
          ? const Center(child:CircularProgressIndicator(color:AppColors.primary))
          : TabBarView(controller:_tab, children:[
              if(widget.ownerMode) _workersTab() else _attendanceTab(),
              if(widget.ownerMode) _advanceTab(),
              if(widget.ownerMode) _salaryTab(),
            ]),
    );
  }

  // ── Attendance Tab ──────────────────────────────────────────────────────
  Widget _attendanceTab(){
    final present = _todayAttendance.values.where((v)=>v).length;
    return Column(children:[
      Container(
        padding:const EdgeInsets.all(14),
        margin:const EdgeInsets.all(14),
        decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[AppColors.primaryDark,AppColors.primary]),
          borderRadius:BorderRadius.circular(14)),
        child:Column(children:[
          Row(children:[
            const Icon(Icons.calendar_today,color:Colors.white,size:16),
            const SizedBox(width:8),
            Text(DateFormat('dd MMM yyyy').format(_attendanceDate),
                style:GoogleFonts.poppins(color:Colors.white,fontWeight:FontWeight.w600)),
            const Spacer(),
            GestureDetector(onTap:_pickAttendanceDate,
              child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(8)),
                child:Text('Change Date',style:GoogleFonts.poppins(color:Colors.white,fontSize:11)))),
          ]),
          const SizedBox(height:10),
          Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
            _attStat('Total','${_workers.length}'),
            _attStat('Present','$present'),
            _attStat('Absent','${_workers.length-present}'),
          ]),
        ]),
      ),
      Expanded(child:ListView.builder(
        padding:const EdgeInsets.fromLTRB(14,0,14,20),
        itemCount:_workers.length,
        itemBuilder:(_,i){
          final w=_workers[i];
          final present=_todayAttendance[w.id]??false;
          return Container(
            margin:const EdgeInsets.only(bottom:8),
            padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:6)]),
            child:Row(children:[
              CircleAvatar(radius:22,
                backgroundColor:(present?AppColors.success:AppColors.error).withOpacity(0.1),
                child:Text(w.name[0].toUpperCase(),style:GoogleFonts.poppins(
                    fontSize:17,fontWeight:FontWeight.w700,
                    color:present?AppColors.success:AppColors.error))),
              const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(w.name,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
                Text(w.role,style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
              ])),
              Column(children:[
                Switch(value:present,
                  activeColor:AppColors.success, inactiveThumbColor:AppColors.error,
                  onChanged:(val) async {
                    await StorageService.instance.setAttendance(w.id,_attendanceDate,val);
                    setState(()=>_todayAttendance[w.id]=val);
                  }),
                Text(present?'Present':'Absent',style:GoogleFonts.poppins(
                    fontSize:10,fontWeight:FontWeight.w600,
                    color:present?AppColors.success:AppColors.error)),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _attStat(String l,String v)=>Column(children:[
    Text(v,style:GoogleFonts.poppins(fontSize:20,fontWeight:FontWeight.w700,color:Colors.white)),
    Text(l,style:GoogleFonts.poppins(fontSize:11,color:Colors.white70)),
  ]);

  Future<void> _pickAttendanceDate() async {
    DateTime sel=_attendanceDate;
    await showDialog(context:context,builder:(ctx)=>Dialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
      child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisSize:MainAxisSize.min,children:[
        TableCalendar(firstDay:DateTime(2020),lastDay:DateTime(2030),focusedDay:sel,
          selectedDayPredicate:(d)=>sameDay(d,sel),
          calendarFormat:CalendarFormat.month,
          headerStyle:const HeaderStyle(formatButtonVisible:false,titleCentered:true),
          calendarStyle:const CalendarStyle(
            selectedDecoration:BoxDecoration(color:AppColors.primary,shape:BoxShape.circle),
            todayDecoration:BoxDecoration(color:Color(0xFF52B78844),shape:BoxShape.circle)),
          onDaySelected:(s,_){sel=s;}),
        ElevatedButton(onPressed:(){_attendanceDate=sel;Navigator.pop(ctx);_load();},
            style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,44)),
            child:const Text('Apply')),
      ])),
    ));
  }

  // ── Workers List Tab (owner) ─────────────────────────────────────────────
  Widget _workersTab()=>_workers.isEmpty
      ? const Center(child:Text('No workers added'))
      : ListView.builder(
          padding:const EdgeInsets.all(14),
          itemCount:_workers.length,
          itemBuilder:(_,i){
            final w=_workers[i];
            return Container(
              margin:const EdgeInsets.only(bottom:10),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:6)]),
              child:Row(children:[
                CircleAvatar(radius:22,backgroundColor:AppColors.primary.withOpacity(0.1),
                  child:Text(w.name[0].toUpperCase(),style:GoogleFonts.poppins(
                      fontSize:17,fontWeight:FontWeight.w700,color:AppColors.primary))),
                const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(w.name,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
                  Text('${w.role} • ${w.city}',style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
                  Text('₹${w.payPerDay.toStringAsFixed(0)}/day • ${w.phone}',
                      style:GoogleFonts.poppins(fontSize:11,color:AppColors.textMedium)),
                ])),
                IconButton(icon:const Icon(Icons.delete_outline,color:AppColors.error,size:20),
                  onPressed:() async {
                    await StorageService.instance.deleteWorker(w.id);
                    _load();
                  }),
              ]),
            );
          });

  // ── Advance Tab ──────────────────────────────────────────────────────────
  Widget _advanceTab(){
    return Column(children:[
      Padding(padding:const EdgeInsets.all(14),
        child:ElevatedButton.icon(
          onPressed:_showAddAdvance,
          icon:const Icon(Icons.add,color:Colors.white),
          label:const Text('Add Advance Payment'),
          style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,46)))),
      Expanded(child:_advances.isEmpty
          ? const Center(child:Text('No advance payments'))
          : ListView.builder(
              padding:const EdgeInsets.fromLTRB(14,0,14,20),
              itemCount:_advances.length,
              itemBuilder:(_,i){
                final a=_advances[i];
                return Container(
                  margin:const EdgeInsets.only(bottom:8),
                  padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10),
                      boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:5)]),
                  child:Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(a.workerName,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
                      Text(DateFormat('dd MMM yyyy').format(a.date),
                          style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
                    ])),
                    Text('₹${a.amount.toStringAsFixed(0)}',style:GoogleFonts.poppins(
                        fontSize:14,fontWeight:FontWeight.w700,color:AppColors.error)),
                  ]),
                );
              })),
    ]);
  }

  // ── Salary Tab ───────────────────────────────────────────────────────────
  Widget _salaryTab(){
    return Column(children:[
      Padding(padding:const EdgeInsets.all(14),
        child:ElevatedButton.icon(
          onPressed:_showSalaryCalculator,
          icon:const Icon(Icons.calculate_outlined,color:Colors.white),
          label:const Text('Calculate & Pay Salary'),
          style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,46)))),
      Expanded(child:_salaries.isEmpty
          ? const Center(child:Text('No salary payments'))
          : ListView.builder(
              padding:const EdgeInsets.fromLTRB(14,0,14,20),
              itemCount:_salaries.length,
              itemBuilder:(_,i){
                final s=_salaries[i];
                final months=['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
                return Container(
                  margin:const EdgeInsets.only(bottom:8),
                  padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10),
                      boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:5)]),
                  child:Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(s.workerName,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w700)),
                      Text('${months[s.month]} ${s.year}',
                          style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
                    ])),
                    Text('₹${s.amount.toStringAsFixed(0)}',style:GoogleFonts.poppins(
                        fontSize:14,fontWeight:FontWeight.w700,color:AppColors.success)),
                  ]),
                );
              })),
    ]);
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  void _showAddWorker(){
    final nameC=TextEditingController(),phoneC=TextEditingController(),
        cityC=TextEditingController(),roleC=TextEditingController(),
        payC=TextEditingController();
    showModalBottomSheet(context:context,isScrollControlled:true,
        backgroundColor:Colors.transparent,
        builder:(ctx)=>Padding(
          padding:EdgeInsets.only(bottom:MediaQuery.of(ctx).viewInsets.bottom),
          child:Container(
            decoration:const BoxDecoration(color:Colors.white,
                borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
            padding:const EdgeInsets.all(20),
            child:Column(mainAxisSize:MainAxisSize.min,
              crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Add Worker',style:GoogleFonts.poppins(
                  fontSize:18,fontWeight:FontWeight.w700)),
              const SizedBox(height:16),
              TextField(controller:nameC,decoration:const InputDecoration(labelText:'Full Name')),
              const SizedBox(height:10),
              TextField(controller:phoneC,keyboardType:TextInputType.phone,
                  decoration:const InputDecoration(labelText:'Mobile No')),
              const SizedBox(height:10),
              TextField(controller:cityC,decoration:const InputDecoration(labelText:'City')),
              const SizedBox(height:10),
              TextField(controller:roleC,decoration:const InputDecoration(labelText:'Role')),
              const SizedBox(height:10),
              TextField(controller:payC,keyboardType:TextInputType.number,
                  decoration:const InputDecoration(labelText:'Pay Per Day ₹')),
              const SizedBox(height:20),
              ElevatedButton(
                onPressed:() async {
                  if(nameC.text.isEmpty) return;
                  final w=WorkerModel(
                    id:DateTime.now().millisecondsSinceEpoch.toString(),
                    name:nameC.text.trim(), phone:phoneC.text.trim(),
                    city:cityC.text.trim(), role:roleC.text.trim(),
                    payPerDay:double.tryParse(payC.text)??0,
                    joiningDate:DateTime.now());
                  await StorageService.instance.saveWorker(w);
                  if(ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,46)),
                child:const Text('Save Worker')),
              const SizedBox(height:10),
            ]),
          ),
        ));
  }

  void _showAddAdvance(){
    if(_workers.isEmpty){showSnack(context,'Add workers first',error:true);return;}
    WorkerModel? sel=_workers.first;
    final amtC=TextEditingController();
    DateTime advDate=DateTime.now();
    showModalBottomSheet(context:context,isScrollControlled:true,
        backgroundColor:Colors.transparent,
        builder:(ctx)=>StatefulBuilder(builder:(ctx,setSt)=>Padding(
          padding:EdgeInsets.only(bottom:MediaQuery.of(ctx).viewInsets.bottom),
          child:Container(
            decoration:const BoxDecoration(color:Colors.white,
                borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
            padding:const EdgeInsets.all(20),
            child:Column(mainAxisSize:MainAxisSize.min,
              crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Add Advance',style:GoogleFonts.poppins(fontSize:18,fontWeight:FontWeight.w700)),
              const SizedBox(height:14),
              DropdownButtonFormField<WorkerModel>(
                value:sel,
                items:_workers.map((w)=>DropdownMenuItem(value:w,child:Text(w.name))).toList(),
                onChanged:(v)=>setSt(()=>sel=v),
                decoration:const InputDecoration(labelText:'Select Worker')),
              const SizedBox(height:10),
              TextField(controller:amtC,keyboardType:TextInputType.number,
                  decoration:const InputDecoration(labelText:'Advance Amount ₹')),
              const SizedBox(height:10),
              GestureDetector(onTap:() async {
                final p=await showDatePicker(context:ctx,
                    initialDate:advDate,firstDate:DateTime(2020),lastDate:DateTime(2030));
                if(p!=null) setSt(()=>advDate=p);
              },
                child:Container(padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(border:Border.all(color:Colors.grey.shade300),
                      borderRadius:BorderRadius.circular(10)),
                  child:Row(children:[
                    const Icon(Icons.calendar_today,color:AppColors.primary,size:16),
                    const SizedBox(width:8),
                    Text(DateFormat('dd MMM yyyy').format(advDate),
                        style:GoogleFonts.poppins(fontSize:13)),
                  ]))),
              const SizedBox(height:16),
              ElevatedButton(onPressed:() async {
                if(sel==null||amtC.text.isEmpty) return;
                final a=AdvancePayment(
                  id:DateTime.now().millisecondsSinceEpoch.toString(),
                  workerId:sel!.id, workerName:sel!.name,
                  amount:double.tryParse(amtC.text)??0, date:advDate);
                await StorageService.instance.addAdvance(a);
                if(ctx.mounted) Navigator.pop(ctx);
                _load();
              },
                style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,46)),
                child:const Text('Save Advance')),
              const SizedBox(height:10),
            ]),
          ),
        )));
  }

  void _showSalaryCalculator(){
    if(_workers.isEmpty){showSnack(context,'No workers',error:true);return;}
    WorkerModel? sel=_workers.first;
    final now=DateTime.now();
    int selMonth=now.month, selYear=now.year;
    showDialog(context:context,builder:(ctx)=>StatefulBuilder(
      builder:(ctx,setSt)=>AlertDialog(
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
        title:Text('Salary Calculator',style:GoogleFonts.poppins(fontWeight:FontWeight.w700)),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          DropdownButtonFormField<WorkerModel>(
            value:sel,
            items:_workers.map((w)=>DropdownMenuItem(value:w,child:Text(w.name))).toList(),
            onChanged:(v)=>setSt(()=>sel=v),
            decoration:const InputDecoration(labelText:'Worker')),
          const SizedBox(height:10),
          DropdownButtonFormField<int>(
            value:selMonth,
            items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,
                child:Text(['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'][i]))).toList(),
            onChanged:(v)=>setSt(()=>selMonth=v!),
            decoration:const InputDecoration(labelText:'Month')),
          const SizedBox(height:10),
          if(sel!=null) FutureBuilder(
            future:_calcSalary(sel!,selMonth,selYear),
            builder:(ctx,snap){
              if(!snap.hasData) return const CircularProgressIndicator();
              final data=snap.data as Map;
              return Container(
                padding:const EdgeInsets.all(12),
                decoration:BoxDecoration(
                    color:AppColors.primary.withOpacity(0.06),
                    borderRadius:BorderRadius.circular(10)),
                child:Column(children:[
                  _sRow2('Days Present',  '${data['days']}'),
                  _sRow2('Pay/Day',       '₹${sel!.payPerDay.toStringAsFixed(0)}'),
                  _sRow2('Gross',         '₹${data['gross'].toStringAsFixed(0)}'),
                  _sRow2('Advance',       '-₹${data['advance'].toStringAsFixed(0)}'),
                  const Divider(),
                  _sRow2('Payable',       '₹${data['payable'].toStringAsFixed(0)}',bold:true),
                ]),
              );
            }),
        ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
          ElevatedButton(onPressed:() async {
            if(sel==null) return;
            final data=await _calcSalary(sel!,selMonth,selYear);
            final sp=SalaryPayment(
              id:DateTime.now().millisecondsSinceEpoch.toString(),
              workerId:sel!.id, workerName:sel!.name,
              month:selMonth, year:selYear,
              amount:data['payable'], paidDate:DateTime.now());
            await StorageService.instance.addSalary(sp);
            if(ctx.mounted) Navigator.pop(ctx);
            _load();
            if(mounted) showSnack(context,'Salary paid!');
          },child:const Text('Pay')),
        ],
      )));
  }

  Future<Map> _calcSalary(WorkerModel w, int month, int year) async {
    final all=await StorageService.instance.getAttendance();
    final days=all.where((a)=>a.workerId==w.id&&a.present&&
        a.date.month==month&&a.date.year==year).length;
    final gross=days*w.payPerDay;
    final adv=_advances.where((a)=>a.workerId==w.id&&
        a.date.month==month&&a.date.year==year)
        .fold(0.0,(s,a)=>s+a.amount);
    return {'days':days,'gross':gross,'advance':adv,'payable':(gross-adv).clamp(0,double.infinity)};
  }

  Widget _sRow2(String l,String v,{bool bold=false})=>Padding(
    padding:const EdgeInsets.symmetric(vertical:3),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(l,style:GoogleFonts.poppins(fontSize:12,color:AppColors.textMedium)),
      Text(v,style:GoogleFonts.poppins(fontSize:12,fontWeight:bold?FontWeight.w700:FontWeight.w500)),
    ]));
}
