
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final paymentsStreamProvider = StreamProvider<List<Map<String,dynamic>>>((ref) =>
  ref.read(firebaseServiceProvider).stream('payments', orderBy: 'paymentDate', descending: true, limit: 100));

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentsStreamProvider);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الدفعات'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/payments/add')),
      ]),
      body: payments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: \$e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد دفعات', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_,__) => const SizedBox(height: 6),
              itemBuilder: (_,i) {
                final p = list[i];
                return Card(child: ListTile(
                  leading: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.accent, size: 22)),
                  title: Row(children: [
                    Expanded(child: Text(p['customerName']??'', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    Text('\${fmt.format(p['amount']??0)} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 15)),
                  ]),
                  subtitle: Text(p['paymentDate']?.toString().substring(0,10)??'—', style: const TextStyle(fontSize: 12)),
                ));
              }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/add'),
        icon: const Icon(Icons.add), label: const Text('دفعة جديدة'), backgroundColor: AppColors.accent),
    );
  }
}
