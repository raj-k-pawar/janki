import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'qr_screen.dart';

class AddBookingScreen extends StatefulWidget {
  final BookingModel? booking;
  const AddBookingScreen({super.key, this.booking});
  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late BookingModel _b;
  bool _saving = false;
  String? _listening;

  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _g10Ctrl = TextEditingController(text: '0');
  final _a10Ctrl = TextEditingController(text: '0');
  final _g3Ctrl = TextEditingController(text: '0');
  final _a3Ctrl = TextEditingController(text: '0');

  late stt.SpeechToText _speech;
  bool _speechOk = false;

  @override
  void initState() {
    super.initState();
    _b = widget.booking != null
        ? BookingModel.fromJson({...widget.booking!.toJson(), 'id': widget.booking!.id})
        : BookingModel();
    _nameCtrl.text = _b.customerName;
    _cityCtrl.text = _b.city;
    _mobileCtrl.text = _b.mobile;
    _g10Ctrl.text = _b.guestsAbove10.toString();
    _a10Ctrl.text = _b.amountAbove10.toString();
    _g3Ctrl.text = _b.guests3To10.toString();
    _a3Ctrl.text = _b.amount3To10.toString();
    _speech = stt.SpeechToText();
    _speech.initialize().then((v) => setState(() => _speechOk = v));
    for (final c in [_g10Ctrl, _a10Ctrl, _g3Ctrl, _a3Ctrl]) c.addListener(_calc);
  }

  void _calc() => setState(() {
    _b.guestsAbove10 = int.tryParse(_g10Ctrl.text) ?? 0;
    _b.amountAbove10 = double.tryParse(_a10Ctrl.text) ?? 0;
    _b.guests3To10 = int.tryParse(_g3Ctrl.text) ?? 0;
    _b.amount3To10 = double.tryParse(_a3Ctrl.text) ?? 0;
    _b.totalGuests = _b.guestsAbove10 + _b.guests3To10;
    _b.totalAmount = (_b.guestsAbove10 * _b.amountAbove10) +
        (_b.guests3To10 * _b.amount3To10) - _b.getFoodDeduction();
  });

  void _setBatch(String v) => setState(() {
    _b.batchType = v;
    if (v == 'full_day')  { _b.foodBreakfast=true; _b.foodLunch=true; _b.foodHighTea=true; _b.foodDinner=false; }
    if (v == 'morning')   { _b.foodBreakfast=true; _b.foodLunch=true; _b.foodHighTea=false;_b.foodDinner=false; }
    if (v == 'afternoon') { _b.foodBreakfast=false;_b.foodLunch=false;_b.foodHighTea=true; _b.foodDinner=true; }
    _calc();
  });

  void _startListen(String key, TextEditingController c) async {
    if (!_speechOk) return;
    setState(() => _listening = key);
    await _speech.listen(onResult: (r) {
      if (r.finalResult) { c.text = r.recognizedWords; setState(() => _listening = null); }
    });
  }

  void _stopListen() { _speech.stop(); setState(() => _listening = null); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _b.customerName = _nameCtrl.text.trim();
    _b.city = _cityCtrl.text.trim();
    _b.mobile = _mobileCtrl.text.trim();
    _b.qrCode = _b.generateQrData();
    setState(() => _saving = true);
    final r = widget.booking?.id != null
        ? await ApiService().updateBooking(widget.booking!.id!, _b.toJson())
        : await ApiService().addBooking(_b.toJson());
    setState(() => _saving = false);
    if (!mounted) return;
    if (r['success'] == true) {
      if (widget.booking == null) {
        _b.id = r['id'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QRScreen(booking: _b)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking updated!'), backgroundColor: AppTheme.primary));
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message'] ?? 'Save failed'), backgroundColor: AppTheme.danger));
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? kb, String? key, String? Function(String?)? validator}) {
    final active = _listening == key;
    return TextFormField(
      controller: c, keyboardType: kb, validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        fillColor: active ? const Color(0xFFFFF8E1) : const Color(0xFFF8FCF8),
        filled: true,
        suffixIcon: key != null && _speechOk
            ? GestureDetector(
                onTapDown: (_) => _startListen(key, c),
                onTapUp: (_) => _stopListen(),
                child: Icon(active ? Icons.mic : Icons.mic_none,
                    color: active ? AppTheme.danger : AppTheme.textLight),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      ),
    );
  }

  Widget _card(List<Widget> kids) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
  );

  Widget _secTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    ]),
  );

  Widget _amtBox(String label, double val, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withOpacity(0.3))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w500)),
      Text('₹${val.toStringAsFixed(0)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: col)),
    ]),
  );

  Widget _batchBtn(String label, String val) => Expanded(
    child: GestureDetector(
      onTap: () => _setBatch(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: _b.batchType == val ? AppTheme.primary : const Color(0xFFF0F4F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: _b.batchType == val ? Colors.white : AppTheme.textMedium)),
      ),
    ),
  );

  Widget _foodChk(String label, bool val, Function(bool?) cb) => Row(mainAxisSize: MainAxisSize.min, children: [
    Checkbox(value: val, onChanged: cb, activeColor: AppTheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
    const SizedBox(width: 6),
  ]);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;
    final above10Amt = _b.guestsAbove10 * _b.amountAbove10;
    final b3Amt = _b.guests3To10 * _b.amount3To10;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Booking' : 'New Customer'),
        backgroundColor: AppTheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _card([
              _secTitle('Customer Information'),
              _field(_nameCtrl, 'Customer Name', Icons.person_outline, key: 'name',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
              const SizedBox(height: 10),
              _field(_cityCtrl, 'City', Icons.location_city_outlined, key: 'city'),
              const SizedBox(height: 10),
              _field(_mobileCtrl, 'Mobile No', Icons.phone_outlined, key: 'mobile', kb: TextInputType.phone,
                  validator: (v) => v != null && v.isNotEmpty && v.length < 10 ? 'Enter valid mobile' : null),
            ]),

            _card([
              _secTitle('Select Batch'),
              Row(children: [
                _batchBtn('Full Day\n(10AM–6PM)', 'full_day'),
                const SizedBox(width: 6),
                _batchBtn('Morning\n(10AM–3PM)', 'morning'),
                const SizedBox(width: 6),
                _batchBtn('Afternoon\n(3PM–8PM)', 'afternoon'),
              ]),
            ]),

            _card([
              _secTitle('Guests Above 10 Years'),
              Row(children: [
                Expanded(child: _field(_g10Ctrl, 'No. of Guests', Icons.group_outlined, kb: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(_a10Ctrl, 'Amount/Person (₹)', Icons.currency_rupee, kb: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              _amtBox('Amount (10+ Yrs)', above10Amt, AppTheme.primary),
            ]),

            _card([
              _secTitle('Guests 3–10 Years'),
              Row(children: [
                Expanded(child: _field(_g3Ctrl, 'No. of Guests', Icons.child_care_outlined, kb: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(_a3Ctrl, 'Amount/Person (₹)', Icons.currency_rupee, kb: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              _amtBox('Amount (3–10 Yrs)', b3Amt, AppTheme.accent),
            ]),

            _card([
              _secTitle('Food Options'),
              Text('Deductions: Breakfast/High Tea = ₹50/guest • Lunch/Dinner = ₹100/guest',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMedium)),
              const SizedBox(height: 8),
              Wrap(children: [
                if (_b.batchType == 'full_day' || _b.batchType == 'morning') ...[
                  _foodChk('Breakfast', _b.foodBreakfast, (v) => setState(() { _b.foodBreakfast=v!; _calc(); })),
                  _foodChk('Lunch', _b.foodLunch, (v) => setState(() { _b.foodLunch=v!; _calc(); })),
                ],
                if (_b.batchType == 'full_day' || _b.batchType == 'afternoon')
                  _foodChk('High Tea', _b.foodHighTea, (v) => setState(() { _b.foodHighTea=v!; _calc(); })),
                if (_b.batchType == 'afternoon')
                  _foodChk('Dinner', _b.foodDinner, (v) => setState(() { _b.foodDinner=v!; _calc(); })),
              ]),
              if (_b.getFoodDeduction() > 0) ...[
                const SizedBox(height: 6),
                Text('Food deduction: –₹${_b.getFoodDeduction().toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ]),

            _card([
              _secTitle('Summary & Payment'),
              Row(children: [
                const Icon(Icons.people, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 6),
                const Text('Total Guests:', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                const Spacer(),
                Text('${_b.totalGuests}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              ]),
              const Divider(height: 16),
              Row(children: [
                const Icon(Icons.payment, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 6),
                const Text('Payment:', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _b.paymentMode,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵  Cash')),
                    DropdownMenuItem(value: 'online', child: Text('📱  Online')),
                  ],
                  onChanged: (v) => setState(() => _b.paymentMode = v!),
                )),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF43A047)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Pay Total Amount', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('₹${_b.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(isEdit ? Icons.save : Icons.qr_code),
                label: Text(isEdit ? 'Update Booking' : 'Save & Generate QR',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _cityCtrl, _mobileCtrl, _g10Ctrl, _a10Ctrl, _g3Ctrl, _a3Ctrl]) c.dispose();
    super.dispose();
  }
}
