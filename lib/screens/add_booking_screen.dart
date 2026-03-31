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
  String? _listeningField;

  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _g10Ctrl = TextEditingController();
  final _a10Ctrl = TextEditingController();
  final _g3Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();

  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.booking;
    if (existing != null) {
      final jsonData = existing.toJson();
      jsonData['id'] = existing.id;
      _b = BookingModel.fromJson(jsonData);
    } else {
      _b = BookingModel();
    }
    _nameCtrl.text = _b.customerName;
    _cityCtrl.text = _b.city;
    _mobileCtrl.text = _b.mobile;
    _g10Ctrl.text = _b.guestsAbove10.toString();
    _a10Ctrl.text = _b.amountAbove10.toString();
    _g3Ctrl.text = _b.guests3To10.toString();
    _a3Ctrl.text = _b.amount3To10.toString();

    _g10Ctrl.addListener(_recalculate);
    _a10Ctrl.addListener(_recalculate);
    _g3Ctrl.addListener(_recalculate);
    _a3Ctrl.addListener(_recalculate);

    _speech = stt.SpeechToText();
    _speech.initialize().then((ok) {
      if (mounted) setState(() => _speechAvailable = ok);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _mobileCtrl.dispose();
    _g10Ctrl.dispose();
    _a10Ctrl.dispose();
    _g3Ctrl.dispose();
    _a3Ctrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      _b.guestsAbove10 = int.tryParse(_g10Ctrl.text) ?? 0;
      _b.amountAbove10 = double.tryParse(_a10Ctrl.text) ?? 0;
      _b.guests3To10 = int.tryParse(_g3Ctrl.text) ?? 0;
      _b.amount3To10 = double.tryParse(_a3Ctrl.text) ?? 0;
      _b.totalGuests = _b.guestsAbove10 + _b.guests3To10;
      final base = (_b.guestsAbove10 * _b.amountAbove10) +
          (_b.guests3To10 * _b.amount3To10);
      _b.totalAmount = base - _b.getFoodDeduction();
    });
  }

  void _setBatch(String batch) {
    setState(() {
      _b.batchType = batch;
      if (batch == 'full_day') {
        _b.foodBreakfast = true;
        _b.foodLunch = true;
        _b.foodHighTea = true;
        _b.foodDinner = false;
      } else if (batch == 'morning') {
        _b.foodBreakfast = true;
        _b.foodLunch = true;
        _b.foodHighTea = false;
        _b.foodDinner = false;
      } else {
        _b.foodBreakfast = false;
        _b.foodLunch = false;
        _b.foodHighTea = true;
        _b.foodDinner = true;
      }
      _recalculate();
    });
  }

  void _startListening(String fieldKey, TextEditingController ctrl) {
    if (!_speechAvailable) return;
    setState(() => _listeningField = fieldKey);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          ctrl.text = result.recognizedWords;
          setState(() => _listeningField = null);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listeningField = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _b.customerName = _nameCtrl.text.trim();
    _b.city = _cityCtrl.text.trim();
    _b.mobile = _mobileCtrl.text.trim();
    _b.qrCode = _b.generateQrData();

    setState(() => _saving = true);

    Map<String, dynamic> result;
    final existingId = widget.booking?.id;
    if (existingId != null) {
      result = await ApiService().updateBooking(existingId, _b.toJson());
    } else {
      result = await ApiService().addBooking(_b.toJson());
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      if (existingId == null) {
        _b.id = result['id'] as int?;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QRScreen(booking: _b)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Save failed'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? voiceKey,
    String? Function(String?)? validator,
  }) {
    final isListening = _listeningField == voiceKey;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        fillColor: isListening
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFF8FCF8),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        suffixIcon: (voiceKey != null && _speechAvailable)
            ? GestureDetector(
                onTapDown: (_) => _startListening(voiceKey, ctrl),
                onTapUp: (_) => _stopListening(),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? AppTheme.danger : AppTheme.textLight,
                ),
              )
            : null,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountDisplay(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Rs.${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _batchButton(String label, String value) {
    final isSelected = _b.batchType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setBatch(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _foodCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;
    final above10Amount = _b.guestsAbove10 * _b.amountAbove10;
    final b3Amount = _b.guests3To10 * _b.amount3To10;
    final deduction = _b.getFoodDeduction();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Info
              _card([
                _sectionTitle('Customer Information'),
                _buildField(
                  ctrl: _nameCtrl,
                  label: 'Customer Name',
                  icon: Icons.person_outline,
                  voiceKey: 'name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                _buildField(
                  ctrl: _cityCtrl,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  voiceKey: 'city',
                ),
                const SizedBox(height: 10),
                _buildField(
                  ctrl: _mobileCtrl,
                  label: 'Mobile No',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  voiceKey: 'mobile',
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 10) {
                      return 'Enter valid mobile number';
                    }
                    return null;
                  },
                ),
              ]),

              // Batch
              _card([
                _sectionTitle('Select Batch'),
                Row(
                  children: [
                    _batchButton('Full Day\n(10AM-6PM)', 'full_day'),
                    const SizedBox(width: 6),
                    _batchButton('Morning\n(10AM-3PM)', 'morning'),
                    const SizedBox(width: 6),
                    _batchButton('Afternoon\n(3PM-8PM)', 'afternoon'),
                  ],
                ),
              ]),

              // Guests above 10
              _card([
                _sectionTitle('Guests Above 10 Years'),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        ctrl: _g10Ctrl,
                        label: 'No. of Guests',
                        icon: Icons.group_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        ctrl: _a10Ctrl,
                        label: 'Amount/Person',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _amountDisplay(
                  'Amount (10+ Yrs)',
                  above10Amount,
                  AppTheme.primary,
                ),
              ]),

              // Guests 3-10
              _card([
                _sectionTitle('Guests 3-10 Years'),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        ctrl: _g3Ctrl,
                        label: 'No. of Guests',
                        icon: Icons.child_care_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        ctrl: _a3Ctrl,
                        label: 'Amount/Person',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _amountDisplay(
                  'Amount (3-10 Yrs)',
                  b3Amount,
                  AppTheme.accent,
                ),
              ]),

              // Food options
              _card([
                _sectionTitle('Food Options'),
                const Text(
                  'Deduct: Breakfast/High Tea = Rs.50/guest  |  Lunch/Dinner = Rs.100/guest',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    if (_b.batchType == 'full_day' || _b.batchType == 'morning') ...[
                      _foodCheckbox('Breakfast', _b.foodBreakfast, (v) {
                        setState(() {
                          _b.foodBreakfast = v ?? true;
                          _recalculate();
                        });
                      }),
                      _foodCheckbox('Lunch', _b.foodLunch, (v) {
                        setState(() {
                          _b.foodLunch = v ?? true;
                          _recalculate();
                        });
                      }),
                    ],
                    if (_b.batchType == 'full_day' ||
                        _b.batchType == 'afternoon') ...[
                      _foodCheckbox('High Tea', _b.foodHighTea, (v) {
                        setState(() {
                          _b.foodHighTea = v ?? false;
                          _recalculate();
                        });
                      }),
                    ],
                    if (_b.batchType == 'afternoon') ...[
                      _foodCheckbox('Dinner', _b.foodDinner, (v) {
                        setState(() {
                          _b.foodDinner = v ?? false;
                          _recalculate();
                        });
                      }),
                    ],
                  ],
                ),
                if (deduction > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Food deduction: -Rs.${deduction.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ]),

              // Summary
              _card([
                _sectionTitle('Summary & Payment'),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: AppTheme.textLight),
                    const SizedBox(width: 6),
                    const Text(
                      'Total Guests:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_b.totalGuests}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: AppTheme.textLight),
                    const SizedBox(width: 6),
                    const Text(
                      'Payment Mode:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _b.paymentMode,
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'online',
                            child: Text('Online'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _b.paymentMode = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pay Total Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs.${_b.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(isEdit ? Icons.save : Icons.qr_code),
                  label: Text(
                    isEdit ? 'Update Booking' : 'Save & Generate QR',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
}
