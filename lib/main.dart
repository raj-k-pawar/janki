import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/canteen_dashboard.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
      home: const RootRouter(),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    final role = auth.currentUser!.role;
    if (role == 'canteen') {
      return const CanteenDashboard();
    }
    return const ManagerDashboard();
  }
}
