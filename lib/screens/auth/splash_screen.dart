import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 54),
            ),
            const SizedBox(height: 22),
            const Text('OSA Management', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Online School Academy', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 36),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
