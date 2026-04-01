import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../services/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _scanning = false;
  bool _processing = false;
  String? _result;
  bool? _success;
  Map<String, dynamic>? _customerData;
  final _db = DatabaseService();

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scan) async {
      if (_processing) return;
      final code = scan.code;
      if (code == null || code.isEmpty) return;

      setState(() {
        _processing = true;
        _scanning = false;
      });

      await _controller?.pauseCamera();
      await _validateQR(code);
    });
  }

  Future<void> _validateQR(String token) async {
    try {
      final res = await _db.validateQR(token);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _success = res['success'] == true;
        _result = res['message'];
        _customerData = res['customer'];
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _success = false;
        _result = 'Connection error';
        _customerData = null;
      });
    }
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _result = null;
      _success = null;
      _customerData = null;
    });
    _controller?.resumeCamera();
  }

  void _reset() {
    setState(() {
      _scanning = false;
      _result = null;
      _success = null;
      _customerData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen - QR Scanner'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => [
              PopupMenuItem(
                  child: Text(auth.user?.fullName ?? ''), enabled: false),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (v) async {
              if (v == 'logout') {
                await auth.logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _scanning
          ? _buildScanner()
          : _result != null
              ? _buildResult()
              : _buildHome(),
    );
  }

  Widget _buildHome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10)
                ],
              ),
              child: const Text('🍛', style: TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 24),
            Text(
              'Canteen Portal',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan customer QR code to validate food order',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.qr_code_scanner, size: 24),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                textStyle: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: AppTheme.primary,
            borderRadius: 12,
            borderLength: 30,
            borderWidth: 8,
            cutOutSize: 260,
          ),
        ),
        if (_processing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Validating QR...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textDark)),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Point camera at QR code',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final isSuccess = _success == true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.cancel,
              color: isSuccess ? AppTheme.success : AppTheme.error,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSuccess ? 'QR Valid! ✅' : 'QR Invalid ❌',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isSuccess ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result ?? '',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),

          if (isSuccess && _customerData != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.success.withOpacity(0.1),
                      blurRadius: 12)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Details',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                  const Divider(),
                  _customerRow(
                      '👤 Name', _customerData!['name']?.toString() ?? ''),
                  _customerRow(
                      '🍛 Package', _customerData!['package_id']?.toString() ?? ''),
                  _customerRow(
                      '👥 Guests', _customerData!['total_guests']?.toString() ?? ''),
                  _customerRow(
                      '🍽️ Lunch/Dinner',
                      (_customerData!['lunch_dinner'] == 1 || _customerData!['lunch_dinner'] == true)
                          ? 'Yes (${_customerData!['lunch_dinner_count']} guests)'
                          : 'No'),
                  _customerRow(
                      '🥐 Breakfast',
                      (_customerData!['breakfast'] == 1 || _customerData!['breakfast'] == true)
                          ? 'Yes'
                          : 'No'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textMedium)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
