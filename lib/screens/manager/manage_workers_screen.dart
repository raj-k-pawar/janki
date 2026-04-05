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
  const ManageWorkersScreen({super.key, this.ownerMode = false});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<WorkerModel>   _workers  = [];
  List<AdvancePayment>_advances = [];
  List<SalaryPayment> _salaries = [];
  bool _loading = true;
  DateTime _attDate = DateTime.now();
  Map<String, bool> _attendance = {};

  @override
  void initState() {
    super.initState();
    final tabCount = widget.ownerMode ? 4 : 1;
    _tab = TabController(length: tabCount, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _workers  = await StorageService.instance.getWorkers();
    _advances = await StorageService.instance.getAdvances();
    _salaries = await StorageService.instance.getSalaries();
    final att = <String, bool>{};
    for (final w in _workers) {
      att[w.id] = await StorageService.instance.getWorkerAttendance(w.id, _attDate);
    }
    setState(() {
      _attendance = att;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.ownerMode
        ? const [
            Tab(text: 'Add Worker'),
            Tab(text: 'Workers'),
            Tab(text: 'Advance'),
            Tab(text: 'Salary'),
          ]
        : const [Tab(text: 'Attendance')];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Workers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tab,
              children: widget.ownerMode
                  ? [
                      _addWorkerTab(),
                      _workersListTab(),
                      _advanceTab(),
                      _salaryTab(),
                    ]
                  : [_attendanceTab()],
            ),
    );
  }

  // ══ TAB: Attendance ════════════════════════════════════════════════════════
  Widget _attendanceTab() {
    final present = _attendance.values.where((v) => v).length;
    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMMM yyyy').format(_attDate),
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: _pickAttDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Change',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 11)),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attStat('Total',   '${_workers.length}'),
                  _attStat('Present', '$present'),
                  _attStat('Absent',  '${_workers.length - present}'),
                ],
              ),
            ],
          ),
        ),
        if (_workers.isEmpty)
          Expanded(
            child: Center(
              child: Text('No workers added yet',
                  style: GoogleFonts.poppins(color: AppColors.textLight)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: _workers.length,
              itemBuilder: (_, i) {
                final w = _workers[i];
                final present = _attendance[w.id] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6),
                    ],
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: (present
                              ? AppColors.success
                              : AppColors.error)
                          .withOpacity(0.12),
                      child: Text(
                        w.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: present
                                ? AppColors.success
                                : AppColors.error),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text('${w.role}  •  ${w.city}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Column(children: [
                      Switch(
                        value: present,
                        activeColor: AppColors.success,
                        inactiveThumbColor: AppColors.error,
                        onChanged: (val) async {
                          await StorageService.instance
                              .setAttendance(w.id, _attDate, val);
                          setState(() => _attendance[w.id] = val);
                        },
                      ),
                      Text(present ? 'Present' : 'Absent',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: present
                                  ? AppColors.success
                                  : AppColors.error)),
                    ]),
                  ]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _attStat(String label, String value) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
    ]);
  }

  Future<void> _pickAttDate() async {
    DateTime sel = _attDate;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: sel,
              selectedDayPredicate: (d) => sameDay(d, sel),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: Color(0x5552B788), shape: BoxShape.circle),
              ),
              onDaySelected: (s, _) => sel = s,
            ),
            ElevatedButton(
              onPressed: () {
                _attDate = sel;
                Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
              child: const Text('Apply'),
            ),
          ]),
        ),
      ),
    );
  }

  // ══ TAB: Add Worker Form ═══════════════════════════════════════════════════
  Widget _addWorkerTab() {
    final nameC  = TextEditingController();
    final phoneC = TextEditingController();
    final cityC  = TextEditingController();
    final roleC  = TextEditingController();
    final payC   = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return StatefulBuilder(builder: (ctx, setSt) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Add New Worker', icon: Icons.person_add_outlined),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(children: [
                  _wField(nameC, 'Full Name', Icons.person_outline, req: true),
                  const SizedBox(height: 12),
                  _wField(phoneC, 'Mobile Number', Icons.phone_outlined,
                      type: TextInputType.phone, req: true),
                  const SizedBox(height: 12),
                  _wField(cityC, 'City', Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _wField(roleC, 'Role / Designation', Icons.work_outline,
                      req: true),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: payC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Pay Per Day (Rs.)',
                      prefixIcon: Icon(Icons.currency_rupee,
                          color: AppColors.primary, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final w = WorkerModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameC.text.trim(),
                          phone: phoneC.text.trim(),
                          city: cityC.text.trim(),
                          role: roleC.text.trim(),
                          payPerDay:
                              double.tryParse(payC.text) ?? 0,
                          joiningDate: DateTime.now(),
                        );
                        await StorageService.instance.saveWorker(w);
                        nameC.clear();
                        phoneC.clear();
                        cityC.clear();
                        roleC.clear();
                        payC.clear();
                        showSnack(context, 'Worker added!');
                        _load();
                      },
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      label: Text('Save Worker',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ══ TAB: Workers List ══════════════════════════════════════════════════════
  Widget _workersListTab() {
    if (_workers.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.badge_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No workers yet',
              style: GoogleFonts.poppins(color: AppColors.textLight)),
          const SizedBox(height: 6),
          Text('Add workers from the "Add Worker" tab',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textLight)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _workers.length,
      itemBuilder: (_, i) {
        final w = _workers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(w.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('${w.phone}  •  ${w.city}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textLight)),
                  Row(children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(w.role,
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Rs.${w.payPerDay.toStringAsFixed(0)}/day',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFFB88B1A),
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () async {
                await StorageService.instance.deleteWorker(w.id);
                _load();
              },
            ),
          ]),
        );
      },
    );
  }

  // ══ TAB: Advance ═══════════════════════════════════════════════════════════
  Widget _advanceTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: ElevatedButton.icon(
          onPressed: _showAddAdvance,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Advance Payment'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46)),
        ),
      ),
      Expanded(
        child: _advances.isEmpty
            ? Center(
                child: Text('No advance payments',
                    style: GoogleFonts.poppins(color: AppColors.textLight)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: _advances.length,
                itemBuilder: (_, i) {
                  final a = _advances[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5),
                      ],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(a.workerName,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(DateFormat('dd MMM yyyy').format(a.date),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textLight)),
                        ]),
                      ),
                      Text('Rs.${a.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error)),
                    ]),
                  );
                }),
      ),
    ]);
  }

  void _showAddAdvance() {
    if (_workers.isEmpty) {
      showSnack(context, 'Add workers first', error: true);
      return;
    }
    WorkerModel? sel = _workers.first;
    final amtC = TextEditingController();
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Add Advance',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorkerModel>(
                value: sel,
                items: _workers
                    .map((w) =>
                        DropdownMenuItem(value: w, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => setSt(() => sel = v),
                decoration: const InputDecoration(labelText: 'Select Worker'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtC,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Advance Amount (Rs.)'),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (p != null) setSt(() => date = p);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(date),
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (sel == null || amtC.text.isEmpty) return;
                  final a = AdvancePayment(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    workerId: sel!.id,
                    workerName: sel!.name,
                    amount: double.tryParse(amtC.text) ?? 0,
                    date: date,
                  );
                  await StorageService.instance.addAdvance(a);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46)),
                child: const Text('Save Advance'),
              ),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }

  // ══ TAB: Salary ═════════════════════════════════════════════════════════════
  Widget _salaryTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: ElevatedButton.icon(
          onPressed: _showSalaryCalc,
          icon: const Icon(Icons.calculate_outlined, color: Colors.white),
          label: const Text('Calculate & Pay Salary'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46)),
        ),
      ),
      Expanded(
        child: _salaries.isEmpty
            ? Center(
                child: Text('No salary payments yet',
                    style: GoogleFonts.poppins(color: AppColors.textLight)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: _salaries.length,
                itemBuilder: (_, i) {
                  final s = _salaries[i];
                  const months = [
                    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5),
                      ],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(s.workerName,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('${months[s.month]} ${s.year}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textLight)),
                        ]),
                      ),
                      Text('Rs.${s.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ]),
                  );
                }),
      ),
    ]);
  }

  void _showSalaryCalc() {
    if (_workers.isEmpty) {
      showSnack(context, 'No workers added', error: true);
      return;
    }
    WorkerModel? sel = _workers.first;
    final now = DateTime.now();
    int selMonth = now.month;
    int selYear  = now.year;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Salary Calculator',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<WorkerModel>(
                value: sel,
                items: _workers
                    .map((w) =>
                        DropdownMenuItem(value: w, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => setSt(() => sel = v),
                decoration:
                    const InputDecoration(labelText: 'Worker'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selMonth,
                    items: List.generate(12, (i) {
                      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                                 'Jul','Aug','Sep','Oct','Nov','Dec'];
                      return DropdownMenuItem(
                          value: i + 1, child: Text(m[i]));
                    }),
                    onChanged: (v) => setSt(() => selMonth = v!),
                    decoration:
                        const InputDecoration(labelText: 'Month'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selYear,
                    items: [2024, 2025, 2026, 2027].map((y) =>
                        DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (v) => setSt(() => selYear = v!),
                    decoration:
                        const InputDecoration(labelText: 'Year'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (sel != null)
                FutureBuilder<Map>(
                  future: _calcSalary(sel!, selMonth, selYear),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final d = snap.data!;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(children: [
                        _calcRow('Days Present',
                            '${d['days']} days'),
                        _calcRow('Pay / Day',
                            'Rs.${sel!.payPerDay.toStringAsFixed(0)}'),
                        _calcRow('Gross Salary',
                            'Rs.${d['gross'].toStringAsFixed(0)}'),
                        _calcRow('Advance Taken',
                            '- Rs.${d['adv'].toStringAsFixed(0)}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payable Amount',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            Text('Rs.${d['pay'].toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (sel == null) return;
                // Check if already paid
                final alreadyPaid = await StorageService.instance
                    .isSalaryPaid(sel!.id, selMonth, selYear);
                if (alreadyPaid) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) showSnack(context,
                      'Salary already paid for this worker this month!',
                      error: true);
                  return;
                }
                final d = await _calcSalary(sel!, selMonth, selYear);
                final sp = SalaryPayment(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  workerId: sel!.id,
                  workerName: sel!.name,
                  month: selMonth,
                  year: selYear,
                  amount: d['pay'],
                  paidDate: DateTime.now(),
                );
                await StorageService.instance.addSalary(sp);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
                if (mounted) showSnack(context, 'Salary paid!');
              },
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
      Text(v, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );

  Future<Map> _calcSalary(WorkerModel w, int month, int year) async {
    final all = await StorageService.instance.getAttendance();
    final days = all
        .where((a) =>
            a.workerId == w.id &&
            a.present &&
            a.date.month == month &&
            a.date.year == year)
        .length;
    final gross = days * w.payPerDay;
    final adv = _advances
        .where((a) =>
            a.workerId == w.id &&
            a.date.month == month &&
            a.date.year == year)
        .fold(0.0, (s, a) => s + a.amount);
    return {
      'days': days,
      'gross': gross,
      'adv': adv,
      'pay': (gross - adv).clamp(0.0, double.infinity),
    };
  }

  // ── Field helpers ──────────────────────────────────────────────────────────
  Widget _wField(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    bool req = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
      validator: req
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
