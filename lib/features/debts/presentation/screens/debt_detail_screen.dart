
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final debtDetailProvider = FutureProvider.family<Map<String,dynamic>?, String>(
  (ref, id) => ref.read(firebaseServiceProvider).get('debts', id));
final debtInstallmentsProvider = StreamProvider.family<List<Map<String,dynamic>>, String>(
  (ref, id) => ref.read(firebaseServiceProvider).stream('installments', where: [['debtId', id]], orderBy: 'installmentNo'));

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debt = ref.watch(debtDetailProvider(debtId));
    final installments = ref.watch(debtInstallmentsProvider(debtId));
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الدين'), actions: [
        IconButton(icon: const Icon(Icons.payment), onPressed: () => context.push('/payments/add?debtId=\$debtId')),
      ]),
      body: debt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: \$e')),
        data: (d) {
          if (d == null) return const Center(child: Text('غير موجود'));
          final total = (d['totalAmount'] as num? ?? 0).toDouble();
          final paid = (d['paidAmount'] as num? ?? 0).toDouble();
          final remaining = total - paid;
          final status = d['status'] as String? ?? 'active';
          return Column(children: [
            Container(padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryLight])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(d['description']??'', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: status.statusColor.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                    child: Text(status.statusLabel, style: TextStyle(color: status.statusColor, fontWeight: FontWeight.w700, fontSize: 12))),
                ]),
                Text(d['customerName']??'', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  _S(fmt.format(total) + ' ر.س', 'الكلي', Colors.white),
                  _S(fmt.format(paid) + ' ر.س', 'المدفوع', const Color(0xFFA8E6CF)),
                  _S(fmt.format(remaining) + ' ر.س', 'المتبقي', remaining > 0 ? const Color(0xFFFFD3B6) : const Color(0xFFA8E6CF)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: total > 0 ? (paid/total).clamp(0.0,1.0) : 0,
                    minHeight: 7, backgroundColor: Colors.white24, color: Colors.white)),
              ])),
            Expanded(child: installments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,_) => Center(child: Text('خطأ: \$e')),
              data: (list) => ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length,
                separatorBuilder: (_,__) => const SizedBox(height: 6),
                itemBuilder: (_,i) {
                  final inst = list[i];
                  final instStatus = inst['status'] as String? ?? 'pending';
                  final amount = (inst['amount'] as num? ?? 0).toDouble();
                  final instId = inst['id'] as String? ?? '';
                  return Card(child: ListTile(
                    leading: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: instStatus.statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text('\${inst['installmentNo']??i+1}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: instStatus.statusColor)))),
                    title: Text(fmt.format(amount) + ' ر.س', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('استحقاق: \${inst['dueDate']?.toString().substring(0,10)??'—'}', style: const TextStyle(fontSize: 12)),
                    trailing: instStatus != 'paid'
                      ? TextButton(onPressed: () => context.push('/payments/add?debtId=\$debtId&installmentId=\$instId'), child: const Text('سداد'))
                      : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Text('مدفوع', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700))),
                  ));
                }),
            )),
          ]);
        },
      ),
    );
  }
  Widget _S(String v, String l, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center),
    Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center)]));
}
