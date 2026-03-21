
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(StreamProvider((r) =>
      r.read(firebaseServiceProvider).stream('subscriptions', orderBy: 'nextRenewal')));
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراكات'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/subscriptions/add')),
      ]),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: \$e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد اشتراكات', style: TextStyle(color: Colors.grey)))
          : ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length,
              separatorBuilder: (_,__) => const SizedBox(height: 8),
              itemBuilder: (_,i) {
                final s = list[i];
                final amount = (s['amount'] as num? ?? 0).toDouble();
                final status = s['status'] as String? ?? 'active';
                return Card(child: ListTile(
                  leading: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: status.statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.subscriptions_outlined, color: status.statusColor)),
                  title: Text(s['planName']??'', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(s['customerName']??'', style: const TextStyle(fontSize: 12)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(fmt.format(amount) + ' ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 14)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: status.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(status.statusLabel, style: TextStyle(color: status.statusColor, fontSize: 10, fontWeight: FontWeight.w700))),
                  ]),
                ));
              }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/subscriptions/add'),
        icon: const Icon(Icons.add), label: const Text('اشتراك جديد')),
    );
  }
}

