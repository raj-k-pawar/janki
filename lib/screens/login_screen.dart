import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'manager/manager_dashboard.dart';
import 'canteen/canteen_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _showRegister = false;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      final role = auth.role;
      if (role == 'canteen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CanteenScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManagerDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('🌾', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 10),
              Text(
                AppConstants.appName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                AppConstants.appNameMarathi,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _showRegister
                          ? RegisterForm(
                              onSwitch: () =>
                                  setState(() => _showRegister = false))
                          : _buildLoginForm(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          Text(
            'Sign in to continue',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => v!.isEmpty ? 'Enter username' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => v!.isEmpty ? 'Enter password' : null,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _login,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Login'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ",
                  style: GoogleFonts.poppins(color: AppTheme.textMedium)),
              GestureDetector(
                onTap: () => setState(() => _showRegister = true),
                child: Text(
                  'Register',
                  style: GoogleFonts.poppins(
                      color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── REGISTER FORM ────────────────────────────────────────────────────────────

class RegisterForm extends StatefulWidget {
  final VoidCallback onSwitch;
  const RegisterForm({super.key, required this.onSwitch});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _selectedRole = 'manager';
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      role: _selectedRole,
      mobile: _mobileCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login.'),
          backgroundColor: AppTheme.success,
        ),
      );
      widget.onSwitch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Create Account',
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          Text(
            'Register to get started',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
            validator: (v) => v!.isEmpty ? 'Enter full name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => v!.isEmpty ? 'Enter username' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Mobile No',
                prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => v!.length < 10 ? 'Enter valid mobile' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
                labelText: 'Role', prefixIcon: Icon(Icons.work_outline)),
            items: AppConstants.userRoles
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(AppConstants.roleDisplay[r] ?? r),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                v!.length < 6 ? 'Password must be 6+ characters' : null,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _register,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Register'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: GoogleFonts.poppins(color: AppTheme.textMedium)),
              GestureDetector(
                onTap: widget.onSwitch,
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                      color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
