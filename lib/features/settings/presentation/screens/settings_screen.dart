
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart' as auth;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _Section('المظهر', [
          _Tile(Icons.dark_mode_outlined, 'الوضع الليلي', 'تفعيل الثيم الداكن',
            trailing: Switch(value: isDark, onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(), activeColor: AppColors.accent)),
        ]),
        _Section('الإشعارات', [
          _Tile(Icons.notifications_outlined, 'تذكير قبل القسط', 'قبل 3 أيام', trailing: Switch(value: true, onChanged: (_){}, activeColor: AppColors.accent)),
          _Tile(Icons.warning_amber_outlined, 'إشعار التأخر', 'عند تجاوز الموعد', trailing: Switch(value: true, onChanged: (_){}, activeColor: AppColors.accent)),
          _Tile(Icons.subscriptions_outlined, 'تجديد الاشتراك', 'قبل 7 أيام', trailing: Switch(value: true, onChanged: (_){}, activeColor: AppColors.accent)),
        ]),
        _Section('النسخ الاحتياطي', [
          _Tile(Icons.cloud_upload_outlined, 'نسخة سحابية', 'Firebase Storage', onTap: () {}),
          _Tile(Icons.file_download_outlined, 'تصدير Excel', 'تصدير كامل البيانات', onTap: () {}),
        ]),
        _Section('الحساب', [
          _Tile(Icons.logout, 'تسجيل الخروج', null, color: AppColors.danger,
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('تسجيل الخروج'),
                content: const Text('هل تريد الخروج؟'),
                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: AppColors.danger)))],
              ));
              if (ok == true) await ref.read(auth.authNotifierProvider.notifier).logout();
            }),
        ]),
        const SizedBox(height: 40),
        const Center(child: Text('SmartDebt Pro v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    );
  }

  Widget _Section(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(4,16,4,8), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight))),
    Card(child: Column(children: children)),
    const SizedBox(height: 4),
  ]);

  Widget _Tile(IconData icon, String title, String? sub, {Widget? trailing, Color? color, VoidCallback? onTap}) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
    title: Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
    subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12)) : null,
    trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_left, color: Colors.grey) : null),
    onTap: onTap,
  );
}
