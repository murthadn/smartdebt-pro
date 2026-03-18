
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary]),
      ),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.white),
        SizedBox(height: 20),
        Text('SmartDebt Pro', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        SizedBox(height: 8),
        Text('جاري التحميل...', style: TextStyle(color: Colors.white60, fontSize: 14)),
        SizedBox(height: 48),
        CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      ])),
    ),
  );
}
