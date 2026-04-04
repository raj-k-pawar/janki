import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class AddCustomerScreen extends StatefulWidget {
  final UserModel managerUser;
  final CustomerModel? existing;
  const AddCustomerScreen({super.key, required this.managerUser, this.existing});
  @override State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _adults10Ctrl = TextEditingController(text:'0');
  final _adultRateCtrl= TextEditingController();
  final _child3Ctrl  = TextEditingController(text:'0');
  final _childRateCtrl= TextEditingController();
  final _breakCtrl   = TextEditingController(text:'0');
  final _lunchCtrl   = TextEditingController(text:'0');
  final _snackCtrl   = TextEditingController(text:'0');
  final _dinnerCtrl  = TextEditingController(text:'0');
  final _advanceCtrl = TextEditingController(text:'0');

  List<PackageModel> _packages = [];
  PackageModel? _selectedPkg;
  PaymentMode _payMode = PaymentMode.cash;
  bool _loading = false;

  int get _adults => int.tryParse(_adults10Ctrl.text)??0;
  int get _children => int.tryParse(_child3Ctrl.text)??0;
  int get _total => _adults + _children;
  double get _adultRate => double.tryParse(_adultRateCtrl.text)??0;
  double get _childRate => double.tryParse(_childRateCtrl.text)??0;
  double get _adultAmt => _adults * _adultRate;
  double get _childAmt => _children * _childRate;

  int get _breakfastGuests => int.tryParse(_breakCtrl.text)??0;
  int get _lunchGuests     => int.tryParse(_lunchCtrl.text)??0;
  int get _snackGuests     => int.tryParse(_snackCtrl.text)??0;
  int get _dinnerGuests    => int.tryParse(_dinnerCtrl.text)??0;

  double get _foodDeduction {
    double d = 0;
    if (_selectedPkg != null) {
      if (_selectedPkg!.breakfast) d += (_total - _breakfastGuests).clamp(0,999) * 50;
      if (_selectedPkg!.lunch)     d += (_total - _lunchGuests).clamp(0,999) * 100;
      if (_selectedPkg!.snacks)    d += (_total - _snackGuests).clamp(0,999) * 50;
      if (_selectedPkg!.dinner)    d += (_total - _dinnerGuests).clamp(0,999) * 100;
    }
    return d;
  }

  double get _advance => double.tryParse(_advanceCtrl.text)??0;
  double get _totalAmt => (_adultAmt + _childAmt - _foodDeduction - _advance).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _loadPackages();
    for (final c in [_adults10Ctrl,_adultRateCtrl,_child3Ctrl,_childRateCtrl,
        _breakCtrl,_lunchCtrl,_snackCtrl,_dinnerCtrl,_advanceCtrl]) {
      c.addListener(() => setState((){}));
    }
    if (widget.existing != null) _populate(widget.existing!);
  }

  Future<void> _loadPackages() async {
    _packages = await StorageService.instance.getPackages();
    setState((){});
  }

  void _populate(CustomerModel c) {
    _nameCtrl.text  = c.name;
    _cityCtrl.text  = c.city;
    _phoneCtrl.text = c.phone;
    _adults10Ctrl.text  = c.adultsCount.toString();
    _adultRateCtrl.text = c.adultRate.toStringAsFixed(0);
    _child3Ctrl.text    = c.childrenCount.toString();
    _childRateCtrl.text = c.childRate.toStringAsFixed(0);
    _breakCtrl.text  = c.food.breakfast.toString();
    _lunchCtrl.text  = c.food.lunch.toString();
    _snackCtrl.text  = c.food.snacks.toString();
    _dinnerCtrl.text = c.food.dinner.toString();
    _advanceCtrl.text = c.advance.toStringAsFixed(0);
    _payMode = c.paymentMode;
  }

  void _selectPackage(PackageModel pkg) {
    setState(() {
      _selectedPkg = pkg;
      _adultRateCtrl.text = pkg.adultPrice.toStringAsFixed(0);
      _childRateCtrl.text = pkg.childPrice.toStringAsFixed(0);
    });
    _updateFoodCounts();
  }

  void _updateFoodCounts() {
    if (_selectedPkg == null) return;
    setState(() {
      if (_selectedPkg!.breakfast) _breakCtrl.text = _total.toString();
      if (_selectedPkg!.lunch)     _lunchCtrl.text = _total.toString();
      if (_selectedPkg!.snacks)    _snackCtrl.text = _total.toString();
      if (_selectedPkg!.dinner)    _dinnerCtrl.text = _total.toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPkg == null) {
      showSnack(context, 'Please select a package', error:true); return;
    }
    setState(() => _loading = true);
    final isEdit = widget.existing != null;
    final id = isEdit ? widget.existing!.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final customer = CustomerModel(
      id: id,
      name: _nameCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      packageId: _selectedPkg!.id,
      packageName: _selectedPkg!.name,
      adultsCount: _adults,
      childrenCount: _children,
      adultRate: _adultRate,
      childRate: _childRate,
      food: FoodCounts(
          breakfast: _breakfastGuests, lunch: _lunchGuests,
          snacks: _snackGuests, dinner: _dinnerGuests),
      advance: _advance,
      paymentMode: _payMode,
      visitDate: DateTime.now(),
      createdAt: isEdit ? widget.existing!.createdAt : DateTime.now(),
      qrCode: isEdit ? widget.existing!.qrCode : 'JAT-$id',
      managerId: widget.managerUser.id,
      managerName: widget.managerUser.fullName,
      qrUsed: isEdit ? widget.existing!.qrUsed : false,
    );
    await StorageService.instance.saveCustomer(customer);
    setState(() => _loading = false);
    if (!mounted) return;
    if (isEdit) {
      showSnack(context, 'Customer updated!');
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder:(_)=>_QrConfirmScreen(customer:customer)));
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl,_cityCtrl,_phoneCtrl,_adults10Ctrl,_adultRateCtrl,
        _child3Ctrl,_childRateCtrl,_breakCtrl,_lunchCtrl,_snackCtrl,_dinnerCtrl,_advanceCtrl])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'New Booking'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color:Colors.white, size:18),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Customer Info
            const SectionHeader('Customer Information', icon:Icons.person_outline),
            WhiteCard(child:Column(children:[
              _tf(_nameCtrl, 'Customer Name', Icons.person_outline, req:true),
              const SizedBox(height:12),
              _tf(_cityCtrl, 'City', Icons.location_city_outlined),
              const SizedBox(height:12),
              _tf(_phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                  type:TextInputType.phone, req:true),
            ])),

            // Package selector
            const SectionHeader('Select Package', icon:Icons.category_outlined),
            if (_packages.isEmpty)
              const Center(child:CircularProgressIndicator(color:AppColors.primary))
            else
              ..._packages.map((pkg) => _packageCard(pkg)),

            if (_selectedPkg != null) ...[
              const SizedBox(height:6),
              // Guest counts
              const SectionHeader('Guest Details', icon:Icons.groups_outlined),
              WhiteCard(child:Column(children:[
                _subHead('🧑 Adults (10+ yrs)'),
                const SizedBox(height:8),
                Row(children:[
                  Expanded(child:_nf(_adults10Ctrl, 'No. of Adults', onChanged:(_){
                    _updateFoodCounts();
                  })),
                  const SizedBox(width:10),
                  Expanded(child:_nf(_adultRateCtrl, 'Rate ₹/person')),
                ]),
                const SizedBox(height:6),
                _amtDisplay('Adults Amount', _adultAmt),

                const Divider(height:20),
                _subHead('👶 Children (3–10 yrs)'),
                const SizedBox(height:8),
                Row(children:[
                  Expanded(child:_nf(_child3Ctrl, 'No. of Children', onChanged:(_){
                    _updateFoodCounts();
                  })),
                  const SizedBox(width:10),
                  Expanded(child:_nf(_childRateCtrl, 'Rate ₹/person')),
                ]),
                const SizedBox(height:6),
                _amtDisplay('Children Amount', _childAmt),
              ])),

              // Food options
              const SectionHeader('Food Options', icon:Icons.restaurant_outlined),
              WhiteCard(child:Column(children:[
                _foodNote(),
                const SizedBox(height:10),
                if (_selectedPkg!.breakfast) _foodRow('🍽️ Breakfast', _breakCtrl, '-₹50/guest'),
                if (_selectedPkg!.lunch)     _foodRow('🍛 Lunch',     _lunchCtrl,  '-₹100/guest'),
                if (_selectedPkg!.snacks)    _foodRow('☕ Snacks',    _snackCtrl,  '-₹50/guest'),
                if (_selectedPkg!.dinner)    _foodRow('🌙 Dinner',   _dinnerCtrl, '-₹100/guest'),
                if (_foodDeduction > 0) ...[
                  const Divider(height:16),
                  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
                    Text('Food Deduction',style:GoogleFonts.poppins(fontSize:12,color:AppColors.error)),
                    Text('-₹${_foodDeduction.toStringAsFixed(0)}',style:GoogleFonts.poppins(
                        fontSize:13,fontWeight:FontWeight.w700,color:AppColors.error)),
                  ]),
                ],
              ])),

              // Advance
              const SectionHeader('Advance', icon:Icons.payments_outlined),
              WhiteCard(child:_nf(_advanceCtrl, 'Advance Amount ₹')),

              // Summary
              const SectionHeader('Summary', icon:Icons.receipt_long_outlined),
              _summaryCard(),

              // Payment mode
              const SectionHeader('Payment Mode', icon:Icons.payment_outlined),
              WhiteCard(child:Row(children:[
                Expanded(child:_payChip('💵 Cash', PaymentMode.cash)),
                const SizedBox(width:10),
                Expanded(child:_payChip('📱 Online', PaymentMode.online)),
              ])),
            ],

            const SizedBox(height:20),
            PrimaryButton(
              label: isEdit ? 'Update Customer' : 'Save & Generate QR',
              icon: isEdit ? Icons.save_outlined : Icons.qr_code_2,
              loading: _loading,
              onTap: _save,
            ),
            const SizedBox(height:30),
          ]),
        ),
      ),
    );
  }

  Widget _packageCard(PackageModel pkg) {
    final sel = _selectedPkg?.id == pkg.id;
    return GestureDetector(
      onTap: () => _selectPackage(pkg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds:200),
        margin: const EdgeInsets.only(bottom:8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200,
              width: sel ? 2 : 1),
          boxShadow: [BoxShadow(
              color: sel ? AppColors.primary.withOpacity(0.25) : Colors.black.withOpacity(0.04),
              blurRadius: sel?10:6, offset:const Offset(0,3))],
        ),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(pkg.name, style:GoogleFonts.poppins(
              fontSize:13, fontWeight:FontWeight.w700,
              color: sel?Colors.white:AppColors.textDark)),
          const SizedBox(height:3),
          Text('⏰ ${pkg.timeSlot}', style:GoogleFonts.poppins(
              fontSize:11, color: sel?Colors.white70:AppColors.textLight)),
          const SizedBox(height:5),
          _foodTags(pkg, sel),
          const SizedBox(height:6),
          Row(children:[
            _priceTag('👶 ₹${pkg.childPrice.toStringAsFixed(0)}', sel),
            const SizedBox(width:8),
            _priceTag('🧑 ₹${pkg.adultPrice.toStringAsFixed(0)}', sel),
          ]),
        ]),
      ),
    );
  }

  Widget _foodTags(PackageModel pkg, bool sel) {
    final items = <String>[];
    if (pkg.breakfast) items.add('🍽️ Breakfast');
    if (pkg.lunch)     items.add('🍛 Lunch');
    if (pkg.snacks)    items.add('☕ Snacks');
    if (pkg.dinner)    items.add('🌙 Dinner');
    return Wrap(spacing:6, children: items.map((t) => Container(
      padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
      decoration: BoxDecoration(
        color: sel?Colors.white24:AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6)),
      child: Text(t, style:GoogleFonts.poppins(
          fontSize:10, color: sel?Colors.white:AppColors.primary)),
    )).toList());
  }

  Widget _priceTag(String t, bool sel) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
    decoration: BoxDecoration(
      color: sel?Colors.white.withOpacity(0.2):AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20)),
    child: Text(t, style:GoogleFonts.poppins(
        fontSize:11, fontWeight:FontWeight.w600,
        color: sel?Colors.white:AppColors.primary)),
  );

  Widget _foodNote() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(
      '⚠️ Reduce guests in food fields to deduct from total.\nBreakfast/Snacks: -₹50/guest, Lunch/Dinner: -₹100/guest',
      style:GoogleFonts.poppins(fontSize:11, color:AppColors.warning),
    ),
  );

  Widget _foodRow(String label, TextEditingController ctrl, String rate) => Padding(
    padding: const EdgeInsets.only(bottom:10),
    child: Row(children:[
      Expanded(flex:3, child:Text(label, style:GoogleFonts.poppins(fontSize:13))),
      Expanded(flex:2, child:TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText:'Guests'),
        onChanged: (_) => setState((){}),
      )),
      const SizedBox(width:8),
      Text(rate, style:GoogleFonts.poppins(fontSize:11, color:AppColors.error)),
    ]),
  );

  Widget _summaryCard() => Container(
    margin: const EdgeInsets.only(bottom:14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors:[AppColors.primaryDark, AppColors.primary],
          begin:Alignment.topLeft, end:Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color:AppColors.primary.withOpacity(0.3),
          blurRadius:10, offset:const Offset(0,5))],
    ),
    child: Column(children:[
      _sRow('Total Guests', '$_total'),
      _sRow('Adults Amt',   '₹${_adultAmt.toStringAsFixed(0)}'),
      _sRow('Children Amt', '₹${_childAmt.toStringAsFixed(0)}'),
      if (_foodDeduction>0) _sRow('Food Deduction','-₹${_foodDeduction.toStringAsFixed(0)}'),
      if (_advance>0)       _sRow('Advance',        '-₹${_advance.toStringAsFixed(0)}'),
      const Divider(color:Colors.white30, height:16),
      _sRow('Pay Total', '₹${_totalAmt.toStringAsFixed(0)}', big:true),
    ]),
  );

  Widget _sRow(String l, String v, {bool big=false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical:3),
    child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
      Text(l, style:GoogleFonts.poppins(fontSize:big?14:12,
          color:Colors.white70, fontWeight:big?FontWeight.w500:FontWeight.w400)),
      Text(v, style:GoogleFonts.poppins(fontSize:big?20:13,
          fontWeight:FontWeight.w700, color:Colors.white)),
    ]),
  );

  Widget _amtDisplay(String l, double amt) => Container(
    margin: const EdgeInsets.only(top:4),
    padding: const EdgeInsets.symmetric(horizontal:12, vertical:7),
    decoration: BoxDecoration(
        color:AppColors.primary.withOpacity(0.07),
        borderRadius:BorderRadius.circular(8)),
    child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
      Text(l, style:GoogleFonts.poppins(fontSize:12, color:AppColors.textMedium)),
      Text('₹${amt.toStringAsFixed(0)}', style:GoogleFonts.poppins(
          fontSize:13, fontWeight:FontWeight.w700, color:AppColors.primary)),
    ]),
  );

  Widget _subHead(String t) => Text(t, style:GoogleFonts.poppins(
      fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textDark));

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool req=false}) =>
    TextFormField(controller:c, keyboardType:type,
      decoration:InputDecoration(labelText:label,
          prefixIcon:Icon(icon,color:AppColors.primary,size:18)),
      validator: req ? (v)=>(v==null||v.trim().isEmpty)?'Required':null : null);

  Widget _nf(TextEditingController c, String label, {void Function(String)? onChanged}) =>
    TextFormField(controller:c,
      keyboardType:const TextInputType.numberWithOptions(decimal:true),
      inputFormatters:[FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration:InputDecoration(labelText:label),
      onChanged:onChanged);

  Widget _payChip(String label, PaymentMode val) {
    final sel = _payMode == val;
    return GestureDetector(
      onTap:()=>setState(()=>_payMode=val),
      child:Container(
        padding:const EdgeInsets.symmetric(vertical:12),
        decoration:BoxDecoration(
          color: sel?AppColors.primary:Colors.grey.shade100,
          borderRadius:BorderRadius.circular(10),
          border:Border.all(color: sel?AppColors.primary:Colors.grey.shade300)),
        child:Center(child:Text(label,style:GoogleFonts.poppins(
            fontSize:13,fontWeight:FontWeight.w600,
            color:sel?Colors.white:AppColors.textMedium))),
      ),
    );
  }
}

// ── QR Confirm Screen ──────────────────────────────────────────────────────
class _QrConfirmScreen extends StatelessWidget {
  final CustomerModel customer;
  const _QrConfirmScreen({required this.customer});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color:Colors.white),
          onPressed: () => Navigator.of(context).popUntil((r)=>r.isFirst),
        ),
      ),
      body: SingleChildScrollView(padding:const EdgeInsets.all(20), children:[
        Container(
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(
              color:AppColors.success.withOpacity(0.1),
              borderRadius:BorderRadius.circular(14),
              border:Border.all(color:AppColors.success.withOpacity(0.4))),
          child:Row(children:[
            Container(width:44,height:44,
              decoration:BoxDecoration(color:AppColors.success,borderRadius:BorderRadius.circular(10)),
              child:const Icon(Icons.check,color:Colors.white,size:26)),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Booking Confirmed!',style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w700,color:AppColors.success)),
              Text('QR generated for canteen – valid today only',
                  style:GoogleFonts.poppins(fontSize:11,color:AppColors.textMedium)),
            ])),
          ]),
        ),
        const SizedBox(height:20),
        Container(
          padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.07),blurRadius:12,offset:const Offset(0,4))]),
          child:Column(children:[
            Text('Canteen Food QR',style:GoogleFonts.poppins(
                fontSize:13,fontWeight:FontWeight.w600,color:AppColors.textMedium)),
            Text('Valid today only · Single use',
                style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
            const SizedBox(height:16),
            QrWidget(data:customer.qrCode),
            const SizedBox(height:12),
            Container(
              padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
              decoration:BoxDecoration(color:AppColors.background,
                  borderRadius:BorderRadius.circular(8)),
              child:Text(customer.qrCode,style:GoogleFonts.poppins(
                  fontSize:13,fontWeight:FontWeight.w600,letterSpacing:1.2)),
            ),
          ]),
        ),
        const SizedBox(height:20),
        WhiteCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Booking Summary',style:GoogleFonts.poppins(
              fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textDark)),
          const SizedBox(height:12),
          _row('Name',   customer.name),
          _row('City',   customer.city),
          _row('Phone',  customer.phone),
          _row('Package',customer.packageName),
          _row('Adults', '${customer.adultsCount} × ₹${customer.adultRate.toStringAsFixed(0)} = ₹${customer.adultAmount.toStringAsFixed(0)}'),
          _row('Children','${customer.childrenCount} × ₹${customer.childRate.toStringAsFixed(0)} = ₹${customer.childAmount.toStringAsFixed(0)}'),
          const Divider(height:16),
          _row('Total Guests','${customer.totalGuests}',bold:true),
          _row('Total Amount','₹${customer.totalAmount.toStringAsFixed(0)}',bold:true),
          _row('Payment',customer.paymentMode==PaymentMode.cash?'Cash':'Online',bold:true),
        ])),
        const SizedBox(height:20),
        ElevatedButton.icon(
          onPressed:()=>Navigator.of(context).popUntil((r)=>r.isFirst),
          icon:const Icon(Icons.dashboard_outlined,color:Colors.white),
          label:const Text('Back to Dashboard'),
          style:ElevatedButton.styleFrom(
              minimumSize:const Size(double.infinity,48)),
        ),
        const SizedBox(height:30),
      ]),
    );
  }
  Widget _row(String l,String v,{bool bold=false})=>Padding(
    padding:const EdgeInsets.symmetric(vertical:3),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(width:110,child:Text(l,style:GoogleFonts.poppins(fontSize:12,color:AppColors.textLight))),
      Expanded(child:Text(v,style:GoogleFonts.poppins(fontSize:12,
          fontWeight:bold?FontWeight.w700:FontWeight.w500,color:AppColors.textDark))),
    ]),
  );
}
