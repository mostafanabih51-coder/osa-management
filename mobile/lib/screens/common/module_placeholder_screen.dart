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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 72, color: AppColors.red),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('القسم جاهز للتنقل وسيتم استكمال وظائفه من داخل النظام.'),
          ]),
        ),
      ),
    );
  }
}
