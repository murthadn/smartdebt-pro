
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/section_header.dart';

final dashboardStatsProvider = FutureProvider<Map<String,dynamic>>((ref) => ref.read(firebaseServiceProvider).getDashboardStats());
final recentPaymentsProvider = StreamProvider<List<Map<String,dynamic>>>((ref) => ref.read(firebaseServiceProvider).stream('payments', orderBy: 'createdAt', descending: true, limit: 8));

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final payments = ref.watch(recentPaymentsProvider);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم'), actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
      ]),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مرحباً 👋', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const Text('اليوم', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text('\${fmt.format(stats.value?['todayCollected'] ?? 0)} ر.س', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ])),
            ])),
          const SizedBox(height: 20),
          SectionHeader(title: 'الإحصائيات', icon: Icons.bar_chart),
          const SizedBox(height: 12),
          stats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,_) => Text('خطأ: \$e'),
            data: (d) => GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(title: 'العملاء', value: '\${d['totalCustomers']}', subtitle: 'عميل مسجل', icon: Icons.people_outline, color: AppColors.primary),
                StatCard(title: 'ديون نشطة', value: '\${d['activeDebts']}', subtitle: 'دين جارٍ', icon: Icons.receipt_long_outlined, color: AppColors.accent),
                StatCard(title: 'متأخرون', value: '\${d['lateDebts']}', subtitle: 'يحتاجون متابعة', icon: Icons.warning_amber_outlined, color: AppColors.warning),
                StatCard(title: 'الاشتراكات', value: '\${d['activeSubscriptions']}', subtitle: 'فعال', icon: Icons.subscriptions_outlined, color: AppColors.primaryLight),
              ],
            ),
          ),
          const SizedBox(height: 20),
          stats.when(
            loading: () => const SizedBox(),
            error: (_,__) => const SizedBox(),
            data: (d) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              _Row(context, 'إجمالي الديون', fmt.format(d['totalDebtAmount']??0), AppColors.primaryLight),
              const Divider(height: 20),
              _Row(context, 'إجمالي المقبوضات', fmt.format(d['totalCollected']??0), AppColors.accent),
              const Divider(height: 20),
              _Row(context, 'إجمالي المتأخرات', fmt.format(d['totalOverdue']??0), AppColors.danger),
            ]))),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'إجراءات سريعة', icon: Icons.flash_on),
          const SizedBox(height: 12),
          Row(children: [
            _Btn('عميل جديد', Icons.person_add_outlined, AppColors.primary, () => context.push('/customers/add')),
            const SizedBox(width: 8),
            _Btn('دين جديد', Icons.add_card_outlined, AppColors.accent, () => context.push('/debts/add')),
            const SizedBox(width: 8),
            _Btn('دفعة', Icons.payments_outlined, AppColors.warning, () => context.push('/payments/add')),
            const SizedBox(width: 8),
            _Btn('تقارير', Icons.bar_chart, AppColors.purple, () => context.push('/reports')),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            SectionHeader(title: 'آخر الدفعات', icon: Icons.payments_outlined),
            const Spacer(),
            TextButton(onPressed: () => context.push('/payments'), child: const Text('الكل')),
          ]),
          const SizedBox(height: 8),
          payments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,_) => Text('خطأ: \$e'),
            data: (list) => list.isEmpty
              ? const Center(child: Text('لا توجد دفعات', style: TextStyle(color: Colors.grey)))
              : Card(child: ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length, separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (_,i) => ListTile(
                    leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_upward, color: AppColors.accent, size: 18)),
                    title: Text(list[i]['customerName']??'', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Text('+\${fmt.format(list[i]['amount']??0)} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ),
                )),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
  Widget _Row(BuildContext ctx, String label, String value, Color color) => Row(children: [
    Container(width: 4, height: 20, color: color, margin: const EdgeInsets.only(left: 12)),
    Text(label, style: const TextStyle(fontSize: 14)),
    const Spacer(),
    Text('\$value ر.س', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
  ]);
  Widget _Btn(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ]),
    ),
  ));
}
