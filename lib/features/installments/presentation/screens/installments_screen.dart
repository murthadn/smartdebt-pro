import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final installmentsStreamProvider = StreamProvider<List<Map<String,dynamic>>>(
  (ref) => ref.read(firebaseServiceProvider).stream(
    'installments', orderBy: 'dueDate'));

class InstallmentsScreen extends ConsumerWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(installmentsStreamProvider);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الأقساط')),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: $e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد أقساط', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_,__) => const SizedBox(height: 8),
              itemBuilder: (_,i) {
                final inst = list[i];
                final amount = (inst['amount'] as num? ?? 0).toDouble();
                final status = inst['status'] as String? ?? 'pending';
                final dueDate = inst['dueDate']?.toString().substring(0,10) ?? '-';
                final instNo = (inst['installmentNo'] ?? i + 1).toString();
                return Card(child: ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: status.statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(instNo,
                      style: TextStyle(fontWeight: FontWeight.w800, color: status.statusColor))),
                  ),
                  title: Text(inst['customerName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('استحقاق: $dueDate',
                    style: const TextStyle(fontSize: 12)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(fmt.format(amount) + ' ر.س',
                      style: TextStyle(fontWeight: FontWeight.w800, color: status.statusColor, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status.statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status.statusLabel,
                        style: TextStyle(color: status.statusColor, fontSize: 10, fontWeight: FontWeight.w700))),
                  ]),
                ));
              },
            ),
      ),
    );
  }
}
