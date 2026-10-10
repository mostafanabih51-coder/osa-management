import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ModulePlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              radius: 28,
              blur: 16,
              borderColor: AppColors.border,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.magenta, AppColors.surfaceDeep],
                    ),
                    border: Border.all(color: AppColors.yellow.withValues(alpha: 0.7)),
                    boxShadow: [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Icon(icon, size: 42, color: AppColors.yellow),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 10),
                const Text(
                  'القسم جاهز للتنقل وسيتم استكمال وظائفه من داخل النظام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
