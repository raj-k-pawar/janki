// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/canteen_dashboard.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: const JankiApp(),
    ),
  );
}

class JankiApp extends StatelessWidget {
  const JankiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janki Agro Tourism',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    final user = auth.currentUser!;

    // Route based on role
    switch (user.role) {
      case 'canteen':
        return const CanteenDashboard();
      case 'manager':
      case 'owner':
      case 'admin':
      default:
        return const ManagerDashboard();
    }
  }
}
