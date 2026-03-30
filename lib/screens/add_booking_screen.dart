// lib/screens/add_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'qr_screen.dart';

class AddBookingScreen extends StatefulWidget {
  final BookingModel? booking; // null = new, non-null = edit
  const AddBookingScreen({super.key, this.booking});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late BookingModel _booking;
  bool _saving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _guests10Ctrl = TextEditingController(text: '0');
  final _amount10Ctrl = TextEditingController(text: '0');
  final _guests3Ctrl = TextEditingController(text: '0');
  final _amount3Ctrl = TextEditingController(text: '0');

  // Speech
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String? _listeningField;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking != null
        ? BookingModel.fromJson(widget.booking!.toJson()..['id'] = widget.booking!.id)
        : BookingModel();

    _nameCtrl.text = _booking.customerName;
    _cityCtrl.text = _booking.city;
    _mobileCtrl.text = _booking.mobile;
    _guests10Ctrl.text = _booking.guestsAbove10.toString();
    _amount10Ctrl.text = _booking.amountAbove10.toString();
    _guests3Ctrl.text = _booking.guests3To10.toString();
    _amount3Ctrl.text = _booking.amount3To10.toString();

    _initSpeech();
    _setupListeners();
  }

  void _setupListeners() {
    _guests10Ctrl.addListener(_recalculate);
    _amount10Ctrl.addListener(_recalculate);
    _guests3Ctrl.addListener(_recalculate);
    _amount3Ctrl.addListener(_recalculate);
  }

  void _recalculate() {
    setState(() {
      _booking.guestsAbove10 = int.tryParse(_guests10Ctrl.text) ?? 0;
      _booking.amountAbove10 = double.tryParse(_amount10Ctrl.text) ?? 0;
      _booking.guests3To10 = int.tryParse(_guests3Ctrl.text) ?? 0;
      _booking.amount3To10 = double.tryParse(_amount3Ctrl.text) ?? 0;
      _booking.totalGuests = _booking.guestsAbove10 + _booking.guests3To10;

      double base = (_booking.guestsAbove10 * _booking.amountAbove10) +
                    (_booking.guests3To10 * _booking.amount3To10);
      _booking.totalAmount = base - _booking.getFoodDeduction();
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  void _startListening(String field, TextEditingController ctrl) async {
    if (!_speechAvailable) return;
    setState(() => _listeningField = field);
    await _speech.listen(onResult: (result) {
      if (result.finalResult) {
        ctrl.text = result.recognizedWords;
        setState(() => _listeningField = null);
      }
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listeningField = null);
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? fieldKey,
    String? Function(String?)? validator,
  }) {
    final isListening = _listeningField == fieldKey;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        suffixIcon: fieldKey != null && _speechAvailable
            ? GestureDetector(
                onTapDown: (_) => _startListening(fieldKey, ctrl),
                onTapUp: (_) => _stopListening(),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? AppTheme.danger : AppTheme.textLight,
                ),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isListening ? const Color(0xFFFFF3E0) : const Color(0xFFF8FCF8),
        labelStyle: const TextStyle(color: AppTheme.textMedium),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(
        color: AppTheme.primary, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    ]),
  );

  Widget _calcDisplay(String label, double value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        Text('₹${value.toStringAsFixed(0)}', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ],
    ),
  );

  void _setBatch(String batch) {
    setState(() {
      _booking.batchType = batch;
      // Set default food options per batch
      if (batch == 'full_day') {
        _booking.foodBreakfast = true;
        _booking.foodLunch = true;
        _booking.foodHighTea = true;
        _booking.foodDinner = false;
      } else if (batch == 'morning') {
        _booking.foodBreakfast = true;
        _booking.foodLunch = true;
        _booking.foodHighTea = false;
        _booking.foodDinner = false;
      } else if (batch == 'afternoon') {
        _booking.foodBreakfast = false;
        _booking.foodLunch = false;
        _booking.foodHighTea = true;
        _booking.foodDinner = true;
      }
      _recalculate();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _booking.customerName = _nameCtrl.text.trim();
    _booking.city = _cityCtrl.text.trim();
    _booking.mobile = _mobileCtrl.text.trim();
    _booking.qrCode = _booking.generateQrData();

    setState(() => _saving = true);

    Map<String, dynamic> result;
    if (widget.booking?.id != null) {
      result = await ApiService().updateBooking(widget.booking!.id!, _booking.toJson());
    } else {
      result = await ApiService().addBooking(_booking.toJson());
    }

    setState(() => _saving = false);

    if (result['success'] == true && mounted) {
      if (widget.booking == null) {
        // New booking - show QR
        final savedId = result['id'];
        _booking.id = savedId;
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => QRScreen(booking: _booking)));
      } else {
        // Edit - go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully!'), backgroundColor: AppTheme.primary));
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Save failed'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;
    final above10Amount = _booking.guestsAbove10 * _booking.amountAbove10;
    final b3Amount = _booking.guests3To10 * _booking.amount3To10;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Booking' : 'New Customer'),
        backgroundColor: AppTheme.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(children: [
                _sectionTitle('Customer Information'),
                _buildTextField(ctrl: _nameCtrl, label: 'Customer Name', icon: Icons.person_outline,
                  fieldKey: 'name',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
                const SizedBox(height: 12),
                _buildTextField(ctrl: _cityCtrl, label: 'City', icon: Icons.location_city_outlined,
                  fieldKey: 'city'),
                const SizedBox(height: 12),
                _buildTextField(ctrl: _mobileCtrl, label: 'Mobile No', icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone, fieldKey: 'mobile',
                  validator: (v) => v != null && v.isNotEmpty && v.length < 10 ? 'Enter valid mobile number' : null),
              ]),
              const SizedBox(height: 14),

              // Batch Selection
              _card(children: [
                _sectionTitle('Select Batch'),
                Row(children: [
                  _batchChip('Full Day\n(10AM - 6PM)', 'full_day'),
                  const SizedBox(width: 8),
                  _batchChip('Morning\n(10AM - 3PM)', 'morning'),
                  const SizedBox(width: 8),
                  _batchChip('Afternoon\n(3PM - 8PM)', 'afternoon'),
                ]),
              ]),
              const SizedBox(height: 14),

              // Guests Above 10
              _card(children: [
                _sectionTitle('Guests Above 10 Years'),
                Row(children: [
                  Expanded(child: _buildTextField(ctrl: _guests10Ctrl, label: 'No. of Guests',
                    icon: Icons.group_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(ctrl: _amount10Ctrl, label: 'Amount / Person',
                    icon: Icons.currency_rupee, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                _calcDisplay('Amount (Above 10 Yrs)', above10Amount, AppTheme.primary),
              ]),
              const SizedBox(height: 14),

              // Guests 3 to 10
              _card(children: [
                _sectionTitle('Guests 3–10 Years'),
                Row(children: [
                  Expanded(child: _buildTextField(ctrl: _guests3Ctrl, label: 'No. of Guests',
                    icon: Icons.child_care_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(ctrl: _amount3Ctrl, label: 'Amount / Person',
                    icon: Icons.currency_rupee, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                _calcDisplay('Amount (3–10 Yrs)', b3Amount, AppTheme.accent),
              ]),
              const SizedBox(height: 14),

              // Food Options
              _card(children: [
                _sectionTitle('Food Options'),
                const Text('Uncheck to deduct: Breakfast/High Tea = ₹50/guest, Lunch/Dinner = ₹100/guest',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMedium)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (_booking.batchType == 'full_day' || _booking.batchType == 'morning') ...[
                    _foodCheck('Breakfast', _booking.foodBreakfast, (v) {
                      setState(() { _booking.foodBreakfast = v!; _recalculate(); });
                    }),
                    _foodCheck('Lunch', _booking.foodLunch, (v) {
                      setState(() { _booking.foodLunch = v!; _recalculate(); });
                    }),
                  ],
                  if (_booking.batchType == 'full_day' || _booking.batchType == 'afternoon') ...[
                    _foodCheck('High Tea', _booking.foodHighTea, (v) {
                      setState(() { _booking.foodHighTea = v!; _recalculate(); });
                    }),
                  ],
                  if (_booking.batchType == 'afternoon')
                    _foodCheck('Dinner', _booking.foodDinner, (v) {
                      setState(() { _booking.foodDinner = v!; _recalculate(); });
                    }),
                ]),
                if (_booking.getFoodDeduction() > 0) ...[
                  const SizedBox(height: 8),
                  Text('Food deduction: -₹${_booking.getFoodDeduction().toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ]),
              const SizedBox(height: 14),

              // Summary
              _card(children: [
                _sectionTitle('Summary'),
                _summaryRow('Total Guests', '${_booking.totalGuests}', Icons.people),
                const Divider(height: 20),
                // Payment Mode
                Row(children: [
                  const Icon(Icons.payment, color: AppTheme.textMedium, size: 18),
                  const SizedBox(width: 8),
                  const Text('Payment Mode:', style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _booking.paymentMode,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('💵  Cash')),
                        DropdownMenuItem(value: 'online', child: Text('📱  Online')),
                      ],
                      onChanged: (v) => setState(() => _booking.paymentMode = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF43A047)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pay Total Amount', style: TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('₹${_booking.totalAmount.toStringAsFixed(0)}', style: const TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(isEdit ? Icons.save : Icons.qr_code),
                  label: Text(isEdit ? 'Update Booking' : 'Save & Generate QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );

  Widget _batchChip(String label, String value) => Expanded(
    child: GestureDetector(
      onTap: () => _setBatch(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: _booking.batchType == value ? AppTheme.primary : const Color(0xFFF0F4F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _booking.batchType == value ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: _booking.batchType == value ? Colors.white : AppTheme.textMedium,
        )),
      ),
    ),
  );

  Widget _foodCheck(String label, bool val, Function(bool?) onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(value: val, onChanged: onChanged, activeColor: AppTheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      const SizedBox(width: 8),
    ],
  );

  Widget _summaryRow(String label, String value, IconData icon) => Row(
    children: [
      Icon(icon, color: AppTheme.textMedium, size: 18),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    ],
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _mobileCtrl.dispose();
    _guests10Ctrl.dispose();
    _amount10Ctrl.dispose();
    _guests3Ctrl.dispose();
    _amount3Ctrl.dispose();
    super.dispose();
  }
}
