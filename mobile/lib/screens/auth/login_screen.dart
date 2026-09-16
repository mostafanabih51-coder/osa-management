import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'role_portal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;
  String? error;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });
    try {
      final result = await ApiService.login(email.text.trim(), password.text);
      final rawUser = result['user'];
      Map<String, dynamic> user = rawUser is Map ? Map<String, dynamic>.from(rawUser) : {};
      if (user.isEmpty) {
        final me = await ApiService.get('user');
        user = me;
      }
      if (!mounted) return;
      final role = '${user['role'] ?? ''}';
      final Widget destination = (role == 'teacher' || role == 'supervisor')
          ? RolePortalScreen(user: user)
          : const DashboardScreen();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => destination), (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Form(
          key: formKey,
          child: Column(children: [
            const Icon(Icons.school_rounded, size: 70, color: AppColors.red),
            const SizedBox(height: 12),
            const Text('OSA Management', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('إدارة Online School Academy', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 28),
            TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)), validator: (value) => value == null || !value.contains('@') ? 'أدخل بريدًا إلكترونيًا صحيحًا' : null),
            const SizedBox(height: 14),
            TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline)), validator: (value) => value == null || value.isEmpty ? 'أدخل كلمة المرور' : null, onFieldSubmitted: (_) => loading ? null : login()),
            if (error != null) ...[const SizedBox(height: 14), Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))],
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: loading ? null : login, child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('دخول'))),
          ]),
        ))),
      )),
    );
  }
}
