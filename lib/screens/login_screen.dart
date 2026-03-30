// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2)],
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.water, size: 60, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('जानकी', style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white,
                        fontFamily: 'Poppins', letterSpacing: 1,
                      )),
                      const Text('Agro Tourism, Boragaon', style: TextStyle(
                        fontSize: 15, color: Color(0xFFB9F6CA), letterSpacing: 0.5,
                      )),
                      const SizedBox(height: 6),
                      const Text('निसर्ग रम्य आनंद यात्रा', style: TextStyle(
                        fontSize: 13, color: Color(0xFF80CBC4), fontStyle: FontStyle.italic,
                      )),
                      const SizedBox(height: 36),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Welcome Back', style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark,
                            )),
                            const SizedBox(height: 4),
                            const Text('Sign in to continue', style: TextStyle(
                              fontSize: 14, color: AppTheme.textMedium,
                            )),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _userCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                child: auth.isLoading
                                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    : const Text('Login', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Role hint
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Column(
                          children: [
                            Text('Default Login Credentials', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            _CredRow('Admin', 'admin / admin123'),
                            _CredRow('Manager', 'manager1 / manager123'),
                            _CredRow('Owner', 'owner1 / owner123'),
                            _CredRow('Canteen', 'canteen1 / canteen123'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String role;
  final String cred;
  const _CredRow(this.role, this.cred);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$role: ', style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
        Text(cred, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    ),
  );
}
