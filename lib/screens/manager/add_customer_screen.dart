import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP 1 – Package Selection Screen
// ══════════════════════════════════════════════════════════════════════════════
class AddCustomerScreen extends StatefulWidget {
  final UserModel managerUser;
  final CustomerModel? existing;
  const AddCustomerScreen({super.key, required this.managerUser, this.existing});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  List<PackageModel> _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _packages = await StorageService.instance.getPackages();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // If editing, skip package selection and go straight to form
    if (widget.existing != null) {
      return BookingFormScreen(
        managerUser: widget.managerUser,
        pkg: null,
        existing: widget.existing,
        packages: _packages,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _packages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 14),
                      Text('No packages configured',
                          style: GoogleFonts.poppins(
                              color: AppColors.textLight, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('Ask the owner to add packages first',
                          style: GoogleFonts.poppins(
                              color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a Package',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text('Tap to select and continue',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 16),
                      ..._packages.map((pkg) => _pkgCard(context, pkg)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _pkgCard(BuildContext context, PackageModel pkg) {
    final foods = <String>[];
    if (pkg.breakfast) foods.add('Breakfast');
    if (pkg.lunch)     foods.add('Lunch');
    if (pkg.snacks)    foods.add('Snacks');
    if (pkg.dinner)    foods.add('Dinner');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingFormScreen(
            managerUser: widget.managerUser,
            pkg: pkg,
            packages: _packages,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(pkg.timeSlot,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                if (foods.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.restaurant_outlined,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(foods.join(' • '),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textMedium)),
                  ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _priceBox('Children (3–10 yrs)',
                        'Rs.${pkg.childPrice.toStringAsFixed(0)}',
                        const Color(0xFFF4A261)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _priceBox('Adults (10+ yrs)',
                        'Rs.${pkg.adultPrice.toStringAsFixed(0)}',
                        AppColors.primary),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox(String label, String price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
        Text(price,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text('per person',
            style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 2 – Booking Form Screen
// ══════════════════════════════════════════════════════════════════════════════
class BookingFormScreen extends StatefulWidget {
  final UserModel managerUser;
  final PackageModel? pkg;
  final CustomerModel? existing;
  final List<PackageModel> packages;

  const BookingFormScreen({
    super.key,
    required this.managerUser,
    required this.pkg,
    required this.packages,
    this.existing,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _adults10  = TextEditingController(text: '0');
  final _adultRate = TextEditingController();
  final _child3    = TextEditingController(text: '0');
  final _childRate = TextEditingController();
  final _breakCtrl = TextEditingController(text: '0');
  final _lunchCtrl = TextEditingController(text: '0');
  final _snackCtrl = TextEditingController(text: '0');
  final _dinnerCtrl= TextEditingController(text: '0');
  final _advCtrl   = TextEditingController(text: '0');

  PackageModel? _selectedPkg;
  PaymentMode _pay = PaymentMode.cash;
  bool _loading = false;

  // ── Calculations ──────────────────────────────────────────────────────────
  int    get _adultCount   => int.tryParse(_adults10.text) ?? 0;
  int    get _childCount   => int.tryParse(_child3.text) ?? 0;
  int    get _totalGuests  => _adultCount + _childCount;
  double get _aRate        => double.tryParse(_adultRate.text) ?? 0;
  double get _cRate        => double.tryParse(_childRate.text) ?? 0;
  double get _adultAmt     => _adultCount * _aRate;
  double get _childAmt     => _childCount * _cRate;
  double get _baseAmt      => _adultAmt + _childAmt;
  double get _advance      => double.tryParse(_advCtrl.text) ?? 0;

  double get _foodDeduction {
    if (_selectedPkg == null) return 0;
    double d = 0;
    if (_selectedPkg!.breakfast) {
      d += (_totalGuests - (int.tryParse(_breakCtrl.text) ?? 0)).clamp(0, 999) * 50;
    }
    if (_selectedPkg!.lunch) {
      d += (_totalGuests - (int.tryParse(_lunchCtrl.text) ?? 0)).clamp(0, 999) * 100;
    }
    if (_selectedPkg!.snacks) {
      d += (_totalGuests - (int.tryParse(_snackCtrl.text) ?? 0)).clamp(0, 999) * 50;
    }
    if (_selectedPkg!.dinner) {
      d += (_totalGuests - (int.tryParse(_dinnerCtrl.text) ?? 0)).clamp(0, 999) * 100;
    }
    return d;
  }

  double get _totalPayable =>
      (_baseAmt - _foodDeduction - _advance).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _populate(widget.existing!);
    } else if (widget.pkg != null) {
      _applyPackage(widget.pkg!);
    }
    for (final c in [
      _adults10, _adultRate, _child3, _childRate,
      _breakCtrl, _lunchCtrl, _snackCtrl, _dinnerCtrl, _advCtrl
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _populate(CustomerModel c) {
    _nameCtrl.text   = c.name;
    _cityCtrl.text   = c.city;
    _phoneCtrl.text  = c.phone;
    _adults10.text   = c.adultsCount.toString();
    _adultRate.text  = c.adultRate.toStringAsFixed(0);
    _child3.text     = c.childrenCount.toString();
    _childRate.text  = c.childRate.toStringAsFixed(0);
    _breakCtrl.text  = c.food.breakfast.toString();
    _lunchCtrl.text  = c.food.lunch.toString();
    _snackCtrl.text  = c.food.snacks.toString();
    _dinnerCtrl.text = c.food.dinner.toString();
    _advCtrl.text    = c.advance.toStringAsFixed(0);
    _pay = c.paymentMode;
    for (final p in widget.packages) {
      if (p.id == c.packageId) {
        _selectedPkg = p;
        break;
      }
    }
  }

  void _applyPackage(PackageModel pkg) {
    _selectedPkg = pkg;
    _adultRate.text = pkg.adultPrice.toStringAsFixed(0);
    _childRate.text = pkg.childPrice.toStringAsFixed(0);
  }

  void _syncFoodToTotal() {
    if (_selectedPkg == null) return;
    setState(() {
      final t = _totalGuests.toString();
      if (_selectedPkg!.breakfast) _breakCtrl.text = t;
      if (_selectedPkg!.lunch)     _lunchCtrl.text = t;
      if (_selectedPkg!.snacks)    _snackCtrl.text = t;
      if (_selectedPkg!.dinner)    _dinnerCtrl.text = t;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _cityCtrl, _phoneCtrl, _adults10, _adultRate,
      _child3, _childRate, _breakCtrl, _lunchCtrl, _snackCtrl,
      _dinnerCtrl, _advCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPkg == null) {
      showSnack(context, 'No package selected', error: true);
      return;
    }
    setState(() => _loading = true);

    final isEdit = widget.existing != null;
    final id = isEdit
        ? widget.existing!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final customer = CustomerModel(
      id: id,
      name:         _nameCtrl.text.trim(),
      city:         _cityCtrl.text.trim(),
      phone:        _phoneCtrl.text.trim(),
      packageId:    _selectedPkg!.id,
      packageName:  _selectedPkg!.name,
      adultsCount:  _adultCount,
      childrenCount:_childCount,
      adultRate:    _aRate,
      childRate:    _cRate,
      food: FoodCounts(
        breakfast: int.tryParse(_breakCtrl.text) ?? 0,
        lunch:     int.tryParse(_lunchCtrl.text) ?? 0,
        snacks:    int.tryParse(_snackCtrl.text) ?? 0,
        dinner:    int.tryParse(_dinnerCtrl.text) ?? 0,
      ),
      advance:      _advance,
      paymentMode:  _pay,
      visitDate:    DateTime.now(),
      createdAt:    isEdit ? widget.existing!.createdAt : DateTime.now(),
      qrCode:       isEdit ? widget.existing!.qrCode : 'JAT-$id',
      managerId:    widget.managerUser.id,
      managerName:  widget.managerUser.fullName,
      qrUsed:       isEdit ? widget.existing!.qrUsed : false,
    );

    await StorageService.instance.saveCustomer(customer);
    setState(() => _loading = false);
    if (!mounted) return;

    if (isEdit) {
      showSnack(context, 'Customer updated successfully!');
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => QrConfirmScreen(customer: customer)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Booking' : 'New Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package banner
              if (_selectedPkg != null) _pkgBanner(_selectedPkg!),

              const SizedBox(height: 4),

              // ── Customer Info ──────────────────────────────────────
              const SectionHeader('Customer Information',
                  icon: Icons.person_outline),
              WhiteCard(
                child: Column(children: [
                  _tf(_nameCtrl, 'Customer Name', Icons.person_outline, req: true),
                  const SizedBox(height: 12),
                  _tf(_cityCtrl, 'City', Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _tf(_phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                      type: TextInputType.phone, req: true),
                ]),
              ),

              // ── Adults ────────────────────────────────────────────
              const SectionHeader('Adults (10+ years)',
                  icon: Icons.person_outlined),
              WhiteCard(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: _numField(_adults10, 'No. of Guests',
                          onChange: (_) => _syncFoodToTotal()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(_adultRate, 'Amount / Person (Rs.)'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _amtDisplay(
                    'Amount (Adults)',
                    'Rs.${_adultAmt.toStringAsFixed(0)}',
                    'Rs.${_adultCount} × Rs.${_aRate.toStringAsFixed(0)}',
                    const Color(0xFF4361EE),
                  ),
                ]),
              ),

              // ── Children ──────────────────────────────────────────
              const SectionHeader('Children (3–10 years)',
                  icon: Icons.child_care_outlined),
              WhiteCard(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: _numField(_child3, 'No. of Guests',
                          onChange: (_) => _syncFoodToTotal()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(_childRate, 'Amount / Person (Rs.)'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _amtDisplay(
                    'Amount (Children)',
                    'Rs.${_childAmt.toStringAsFixed(0)}',
                    '${_childCount} × Rs.${_cRate.toStringAsFixed(0)}',
                    const Color(0xFFF4A261),
                  ),
                ]),
              ),

              // ── Food Options ──────────────────────────────────────
              if (_selectedPkg != null &&
                  (_selectedPkg!.breakfast ||
                      _selectedPkg!.lunch ||
                      _selectedPkg!.snacks ||
                      _selectedPkg!.dinner)) ...[
                const SectionHeader('Food Options',
                    icon: Icons.restaurant_outlined),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reduce guest count below total to apply deduction:\n'
                          'Breakfast / Snacks = -Rs.50 per guest\n'
                          'Lunch / Dinner = -Rs.100 per guest',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.warning),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_selectedPkg!.breakfast)
                        _foodRow('🍽️  Breakfast', _breakCtrl, 50),
                      if (_selectedPkg!.lunch)
                        _foodRow('🍛  Lunch', _lunchCtrl, 100),
                      if (_selectedPkg!.snacks)
                        _foodRow('☕  Snacks', _snackCtrl, 50),
                      if (_selectedPkg!.dinner)
                        _foodRow('🌙  Dinner', _dinnerCtrl, 100),
                      if (_foodDeduction > 0) ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Food Deduction',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error)),
                            Text('- Rs.${_foodDeduction.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Advance ───────────────────────────────────────────
              const SectionHeader('Advance Payment', icon: Icons.payments_outlined),
              WhiteCard(
                child: Column(children: [
                  _numField(_advCtrl, 'Advance Amount (Rs.)'),
                  if (_advance > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Advance',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.textMedium)),
                        Text('- Rs.${_advance.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error)),
                      ],
                    ),
                  ],
                ]),
              ),

              // ── Summary ───────────────────────────────────────────
              const SectionHeader('Summary', icon: Icons.receipt_long_outlined),
              _summaryCard(),

              // ── Payment Mode ──────────────────────────────────────
              const SectionHeader('Payment Mode', icon: Icons.payment_outlined),
              WhiteCard(
                child: Row(children: [
                  Expanded(child: _payChip('💵  Cash', PaymentMode.cash)),
                  const SizedBox(width: 12),
                  Expanded(child: _payChip('📱  Online', PaymentMode.online)),
                ]),
              ),

              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Update Booking' : 'Save & Generate QR',
                icon: isEdit ? Icons.save_outlined : Icons.qr_code_2,
                loading: _loading,
                onTap: _save,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _pkgBanner(PackageModel pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.category_outlined, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selected Package',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
            Text(pkg.name,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(pkg.timeSlot,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }

  Widget _amtDisplay(String label, String amount, String calc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textMedium)),
            Text(calc,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textLight)),
          ]),
        ),
        Text(amount,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _foodRow(String label, TextEditingController ctrl, int rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(label,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark)),
        ),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Guests'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Text('-Rs.$rate/g',
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.error)),
      ]),
    );
  }

  Widget _summaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: [
        _sRow('Total Guests',  '$_totalGuests'),
        _sRow('Adults Amount', 'Rs.${_adultAmt.toStringAsFixed(0)}'),
        _sRow('Children Amount','Rs.${_childAmt.toStringAsFixed(0)}'),
        const Divider(color: Colors.white30, height: 16),
        _sRow('Sub Total',     'Rs.${_baseAmt.toStringAsFixed(0)}'),
        if (_foodDeduction > 0)
          _sRow('Food Deduction', '- Rs.${_foodDeduction.toStringAsFixed(0)}',
              valueColor: const Color(0xFFFFB3B3)),
        if (_advance > 0)
          _sRow('Advance',       '- Rs.${_advance.toStringAsFixed(0)}',
              valueColor: const Color(0xFFFFB3B3)),
        const Divider(color: Colors.white30, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('PAY TOTAL',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
          Text('Rs.${_totalPayable.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _sRow(String l, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
        Text(v,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.white)),
      ]),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool req = false}) {
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

  Widget _numField(TextEditingController c, String label,
      {void Function(String)? onChange}) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: label),
      onChanged: onChange,
    );
  }

  Widget _payChip(String label, PaymentMode val) {
    final sel = _pay == val;
    return GestureDetector(
      onTap: () => setState(() => _pay = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textMedium)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QR Confirmation Screen
// ══════════════════════════════════════════════════════════════════════════════
class QrConfirmScreen extends StatelessWidget {
  final CustomerModel customer;
  const QrConfirmScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Confirmed!',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                      Text('QR code generated for canteen - valid today only',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textMedium)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // QR Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                Text('Canteen Food QR Code',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium)),
                const SizedBox(height: 4),
                Text('Valid today only  •  Single use',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textLight)),
                const SizedBox(height: 16),
                QrWidget(data: customer.qrCode, size: 180),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(customer.qrCode,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppColors.textDark)),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Summary',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 14),
                  _infoRow('Name',    customer.name),
                  _infoRow('City',    customer.city),
                  _infoRow('Phone',   customer.phone),
                  _infoRow('Package', customer.packageName),
                  const Divider(height: 16),
                  _infoRow('Adults',
                      '${customer.adultsCount} x Rs.${customer.adultRate.toStringAsFixed(0)} = Rs.${customer.adultAmount.toStringAsFixed(0)}'),
                  _infoRow('Children',
                      '${customer.childrenCount} x Rs.${customer.childRate.toStringAsFixed(0)} = Rs.${customer.childAmount.toStringAsFixed(0)}'),
                  const Divider(height: 16),
                  _infoRow('Total Guests',  '${customer.totalGuests}'),
                  _infoRow('Base Amount',   'Rs.${customer.baseAmount.toStringAsFixed(0)}'),
                  if (customer.advance > 0)
                    _infoRow('Advance Paid', 'Rs.${customer.advance.toStringAsFixed(0)}'),
                  const Divider(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PAY TOTAL',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        Text('Rs.${customer.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Payment',
                      customer.paymentMode == PaymentMode.cash
                          ? 'Cash'
                          : 'Online'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(Icons.person_add_outlined,
                      color: Colors.white, size: 18),
                  label: Text('Add Another',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textLight)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }
}
