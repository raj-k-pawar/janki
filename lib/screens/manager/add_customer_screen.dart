import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import 'qr_display_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerModel? editCustomer;
  const AddCustomerScreen({super.key, this.editCustomer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  bool _saving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _guestsAbove10Ctrl = TextEditingController(text: '0');
  final _amtAbove10Ctrl = TextEditingController(text: '0');
  final _guests3to10Ctrl = TextEditingController(text: '0');
  final _amt3to10Ctrl = TextEditingController(text: '0');
  final _lunchDinnerCountCtrl = TextEditingController(text: '0');

  PackageModel? _selectedPackage;
  String _paymentMode = 'cash';
  bool _lunchDinner = true;
  bool _breakfast = false;

  // Computed
  double _amtGuessAbove10 = 0;
  double _amtGuest3to10 = 0;
  double _totalAmount = 0;
  int _totalGuests = 0;

  @override
  void initState() {
    super.initState();
    if (widget.editCustomer != null) _prefillEdit();
    _guestsAbove10Ctrl.addListener(_recalculate);
    _amtAbove10Ctrl.addListener(_recalculate);
    _guests3to10Ctrl.addListener(_recalculate);
    _amt3to10Ctrl.addListener(_recalculate);
  }

  void _prefillEdit() {
    final c = widget.editCustomer!;
    _nameCtrl.text = c.name;
    _cityCtrl.text = c.city;
    _mobileCtrl.text = c.mobile;
    _guestsAbove10Ctrl.text = c.guestsAbove10.toString();
    _amtAbove10Ctrl.text = c.amountAbove10.toString();
    _guests3to10Ctrl.text = c.guests3to10.toString();
    _amt3to10Ctrl.text = c.amount3to10.toString();
    _paymentMode = c.paymentMode;
    _lunchDinner = c.lunchDinner;
    _breakfast = c.breakfast;
    _lunchDinnerCountCtrl.text = c.lunchDinnerCount.toString();
    _selectedPackage =
        allPackages.firstWhere((p) => p.id == c.packageId, orElse: () => allPackages[0]);
    _recalculate();
  }

  void _recalculate() {
    final g1 = int.tryParse(_guestsAbove10Ctrl.text) ?? 0;
    final a1 = double.tryParse(_amtAbove10Ctrl.text) ?? 0;
    final g2 = int.tryParse(_guests3to10Ctrl.text) ?? 0;
    final a2 = double.tryParse(_amt3to10Ctrl.text) ?? 0;

    setState(() {
      _amtGuessAbove10 = g1 * a1;
      _amtGuest3to10 = g2 * a2;
      _totalGuests = g1 + g2;
      _totalAmount = _amtGuessAbove10 + _amtGuest3to10;
      _lunchDinnerCountCtrl.text = _totalGuests.toString();
    });
  }

  void _onPackageSelected(PackageModel pkg) {
    setState(() {
      _selectedPackage = pkg;
      _amtAbove10Ctrl.text = pkg.priceAbove10.toString();
      _amt3to10Ctrl.text = pkg.price3to10.toString();
    });
    _recalculate();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a package'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      'package_id': _selectedPackage!.id,
      'guests_above_10': int.tryParse(_guestsAbove10Ctrl.text) ?? 0,
      'guests_3to10': int.tryParse(_guests3to10Ctrl.text) ?? 0,
      'amount_above_10': _amtGuessAbove10,
      'amount_3to10': _amtGuest3to10,
      'total_amount': _totalAmount,
      'payment_mode': _paymentMode,
      'lunch_dinner': _lunchDinner ? 1 : 0,
      'breakfast': _breakfast ? 1 : 0,
      'lunch_dinner_count': int.tryParse(_lunchDinnerCountCtrl.text) ?? 0,
    };

    try {
      Map<String, dynamic> res;
      if (widget.editCustomer != null) {
        res = await _db.updateCustomer(widget.editCustomer!.id!, data);
      } else {
        res = await _db.addCustomer(data);
      }

      setState(() => _saving = false);

      if (!mounted) return;
      if (res['success'] == true) {
        if (widget.editCustomer == null) {
          // Show QR
          final qrToken = res['qr_token'] ?? '';
          final customerId = res['customer_id'] ?? 0;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QrDisplayScreen(
                qrToken: qrToken,
                customerName: _nameCtrl.text.trim(),
                packageName: _selectedPackage!.nameMarathi,
                totalGuests: _totalGuests,
                totalAmount: _totalAmount,
                customerId: customerId,
              ),
            ),
          );
        } else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to save'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _mobileCtrl.dispose();
    _guestsAbove10Ctrl.dispose();
    _amtAbove10Ctrl.dispose();
    _guests3to10Ctrl.dispose();
    _amt3to10Ctrl.dispose();
    _lunchDinnerCountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.editCustomer != null ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionCard('Customer Details', [
                _field(_nameCtrl, 'Customer Name', Icons.person_outline,
                    required: true),
                const SizedBox(height: 14),
                _field(_cityCtrl, 'City', Icons.location_city_outlined,
                    required: true),
                const SizedBox(height: 14),
                _field(_mobileCtrl, 'Mobile No', Icons.phone_outlined,
                    keyboardType: TextInputType.phone, required: true,
                    validator: (v) =>
                        v!.length < 10 ? 'Enter valid mobile no' : null),
              ]),

              const SizedBox(height: 16),

              // Package Selection
              _buildPackageSection(),

              const SizedBox(height: 16),

              // Guests Above 10
              _sectionCard('Guests Above 10 Years', [
                Row(
                  children: [
                    Expanded(
                      child: _field(_guestsAbove10Ctrl, 'No. of Guests',
                          Icons.people,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_amtAbove10Ctrl, 'Amount per Person',
                          Icons.currency_rupee,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _amountDisplay(
                    'Total Amount (Above 10 yr)', _amtGuessAbove10),
              ]),

              const SizedBox(height: 16),

              // Guests 3-10
              _sectionCard('Guests 3 to 10 Years', [
                Row(
                  children: [
                    Expanded(
                      child: _field(_guests3to10Ctrl, 'No. of Guests',
                          Icons.child_care,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_amt3to10Ctrl, 'Amount per Person',
                          Icons.currency_rupee,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _amountDisplay('Total Amount (3-10 yr)', _amtGuest3to10),
              ]),

              const SizedBox(height: 16),

              // Food Options
              _sectionCard('Food Options', [
                _foodToggle(
                  '🍛 Lunch / Dinner',
                  _lunchDinner,
                  (v) => setState(() => _lunchDinner = v),
                ),
                if (_lunchDinner) ...[
                  const SizedBox(height: 10),
                  _field(_lunchDinnerCountCtrl, 'No. of Guests for Lunch/Dinner',
                      Icons.restaurant,
                      keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 10),
                _foodToggle(
                  '🍽️ Breakfast',
                  _breakfast,
                  (v) => setState(() => _breakfast = v),
                ),
              ]),

              const SizedBox(height: 16),

              // Summary
              _sectionCard('Booking Summary', [
                _summaryRow('Total Guests', _totalGuests.toString()),
                const Divider(height: 20),
                _summaryRow('Total Amount', '₹${_totalAmount.toStringAsFixed(2)}',
                    valueColor: AppTheme.primary, bold: true),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵 Cash')),
                    DropdownMenuItem(
                        value: 'online', child: Text('📱 Online')),
                  ],
                  onChanged: (v) => setState(() => _paymentMode = v!),
                ),
              ]),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving
                    ? 'Saving...'
                    : widget.editCustomer != null
                        ? 'Update Customer'
                        : 'Save & Generate QR'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Select Package',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark),
            ),
          ),
          ...allPackages.map((pkg) => _packageTile(pkg)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _packageTile(PackageModel pkg) {
    final selected = _selectedPackage?.id == pkg.id;
    return InkWell(
      onTap: () => _onPackageSelected(pkg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pkg.nameMarathi,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? AppTheme.primary : AppTheme.textDark,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(pkg.timing,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppTheme.textMedium)),
            Text(pkg.includes,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppTheme.textLight)),
            const SizedBox(height: 4),
            Row(
              children: [
                _priceChip('👶 ₹${pkg.price3to10}', Colors.blue),
                const SizedBox(width: 8),
                _priceChip('🧑 ₹${pkg.priceAbove10}', AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool required = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator ??
          (required
              ? (v) => v!.isEmpty ? 'Required' : null
              : null),
    );
  }

  Widget _amountDisplay(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textMedium)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _foodToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textDark)),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textMedium)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
