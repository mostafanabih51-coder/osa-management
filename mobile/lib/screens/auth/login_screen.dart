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
  bool hidePassword = true;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate() || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.login(email.text.trim(), password.text);
      final rawUser = result['user'];
      Map<String, dynamic> user = rawUser is Map
          ? Map<String, dynamic>.from(rawUser)
          : <String, dynamic>{};
      if (user.isEmpty) user = await ApiService.get('user');
      if (!mounted) return;
      final role = '${user['role'] ?? ''}';
      final Widget destination =
          (role == 'teacher' || role == 'supervisor')
              ? RolePortalScreen(user: user)
              : const DashboardScreen();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.surfaceDeep,
                    AppColors.navy,
                    AppColors.surfaceDeep,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -70,
            child: _GlowOrb(color: AppColors.magenta.withValues(alpha: 0.20), size: 240),
          ),
          Positioned(
            bottom: -90,
            left: -75,
            child: _GlowOrb(color: AppColors.yellow.withValues(alpha: 0.10), size: 220),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.magenta,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.magenta.withValues(alpha: 0.30),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, color: AppColors.yellow, size: 46),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Online School Academy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, color: AppColors.yellow, size: 17),
                            SizedBox(width: 7),
                            Text(
                              'نظام إدارة الأكاديمية',
                              style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(23),
                        decoration: BoxDecoration(
                          color: AppColors.magenta,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'أهلًا بيك',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'سجّل دخولك للمتابعة وإدارة حسابك.',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                              ),
                              const SizedBox(height: 23),
                              TextFormField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (value) => value == null || !value.contains('@')
                                    ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: password,
                                obscureText: hidePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: hidePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                                    onPressed: () => setState(() => hidePassword = !hidePassword),
                                    icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'أدخل كلمة المرور' : null,
                                onFieldSubmitted: (_) => login(),
                              ),
                              if (error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.magenta.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(color: AppColors.magenta.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppColors.yellow, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          error!,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(color: Colors.white, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: loading ? null : login,
                                  child: loading
                                      ? const SizedBox(
                                          width: 23,
                                          height: 23,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded, size: 20),
                                            SizedBox(width: 9),
                                            Text('دخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Online School Academy  •  OSA',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
