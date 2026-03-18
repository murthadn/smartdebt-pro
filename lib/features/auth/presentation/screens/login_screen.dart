
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    ref.read(authNotifierProvider).whenOrNull(
      data: (u) { if (u != null && mounted) context.go('/dashboard'); },
      error: (e, _) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger)); },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authNotifierProvider).isLoading;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary]),
        ),
        child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
          const SizedBox(height: 48),
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 44, color: Colors.white)),
          const SizedBox(height: 16),
          const Text('SmartDebt Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const Text('إدارة الديون والمشتركين', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 48),
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('تسجيل الدخول', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _passCtrl, obscureText: _obscure,
                decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
                validator: (v) => (v?.length ?? 0) < 6 ? 'كلمة المرور قصيرة' : null),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: loading ? null : _login,
                child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('دخول')),
            ]))),
          const SizedBox(height: 24),
          const Text('SmartDebt Pro v1.0.0', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]))),
      ),
    );
  }
}
