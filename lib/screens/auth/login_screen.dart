import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../manager/manager_dashboard.dart';
import '../owner/owner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;

  Future<void> _login() async {
    final u = _user.text.trim(); final p = _pass.text;
    if (u.isEmpty || p.isEmpty) return;
    setState(() => _loading = true);
    final user = await StorageService.instance.login(u, p);
    setState(() => _loading = false);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid username or password',style:GoogleFonts.poppins()),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    Widget dest;
    if (user.role == UserRole.owner || user.role == UserRole.admin) {
      dest = OwnerDashboard(user: user);
    } else {
      dest = ManagerDashboard(user: user);
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>dest));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors:[AppColors.primaryDark, AppColors.primary, Color(0xFF52B788)],
            begin:Alignment.topLeft, end:Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 40),
            Container(
              width:80, height:80,
              decoration: BoxDecoration(color:Colors.white,
                  borderRadius:BorderRadius.circular(20)),
              child: const Center(child:Text('🌿',style:TextStyle(fontSize:42))),
            ),
            const SizedBox(height:16),
            Text('Janki Agro Tourism', style:GoogleFonts.poppins(
                fontSize:22, fontWeight:FontWeight.w700, color:Colors.white)),
            Text('Management Portal', style:GoogleFonts.poppins(
                fontSize:12, color:Colors.white70, letterSpacing:1.5)),
            const SizedBox(height:40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color:Colors.white,
                  borderRadius:BorderRadius.circular(20)),
              child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                Text('Sign In', style:GoogleFonts.poppins(
                    fontSize:20, fontWeight:FontWeight.w700, color:AppColors.textDark)),
                const SizedBox(height:20),
                TextField(controller:_user,
                  decoration:InputDecoration(labelText:'Username',
                      prefixIcon:Icon(Icons.person_outline,color:AppColors.primary))),
                const SizedBox(height:14),
                TextField(controller:_pass, obscureText:_obscure,
                  decoration:InputDecoration(labelText:'Password',
                    prefixIcon:Icon(Icons.lock_outline,color:AppColors.primary),
                    suffixIcon:IconButton(
                      icon:Icon(_obscure?Icons.visibility_off_outlined:Icons.visibility_outlined,
                          color:AppColors.textLight),
                      onPressed:()=>setState(()=>_obscure=!_obscure)),
                  )),
                const SizedBox(height:24),
                SizedBox(width:double.infinity, height:48,
                  child:ElevatedButton(
                    onPressed:_loading?null:_login,
                    child:_loading
                        ? const SizedBox(width:22,height:22,
                            child:CircularProgressIndicator(color:Colors.white,strokeWidth:2.5))
                        : Text('Sign In',style:GoogleFonts.poppins(
                            fontSize:15,fontWeight:FontWeight.w600,color:Colors.white)),
                  )),
              ]),
            ),
            const SizedBox(height:20),
            Container(
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                  color:Colors.white.withOpacity(0.15),
                  borderRadius:BorderRadius.circular(12),
                  border:Border.all(color:Colors.white30)),
              child:Column(children:[
                Text('Demo Credentials',style:GoogleFonts.poppins(
                    color:Colors.white,fontWeight:FontWeight.w600,fontSize:13)),
                const SizedBox(height:8),
                _cred('Manager','manager1','manager123'),
                _cred('Owner','owner1','owner123'),
                _cred('Admin','admin1','admin123'),
              ]),
            ),
          ]),
        )),
      ),
    );
  }
  Widget _cred(String role, String u, String p) => Padding(
    padding:const EdgeInsets.symmetric(vertical:2),
    child:Text('$role: $u / $p',style:GoogleFonts.poppins(
        color:Colors.white,fontSize:11)),
  );
}
