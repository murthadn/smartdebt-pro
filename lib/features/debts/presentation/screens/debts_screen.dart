
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final debtFilterProvider = StateProvider<String>((ref) => 'all');
final debtsStreamProvider = StreamProvider<List<Map<String,dynamic>>>((ref) =>
  ref.read(firebaseServiceProvider).stream('debts', orderBy: 'createdAt', descending: true));
final filteredDebtsProvider = Provider<AsyncValue<List<Map<String,dynamic>>>>((ref) {
  final filter = ref.watch(debtFilterProvider);
  return ref.watch(debtsStreamProvider).whenData((list) =>
    filter == 'all' ? list : list.where((d) => d['status'] == filter).toList());
});

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(filteredDebtsProvider);
    final filter = ref.watch(debtFilterProvider);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الديون'), actions: [
        IconButton(icon: const Icon(Icons.add_card_outlined), onPressed: () => context.push('/debts/add')),
      ]),
      body: Column(children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: ['all','active','late','completed','cancelled'].map((f) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(label: Text({'all':'الكل','active':'نشط','late':'متأخر','completed':'مكتمل','cancelled':'ملغي'}[f]!),
              selected: filter == f, onSelected: (_) => ref.read(debtFilterProvider.notifier).state = f))).toList())),
        Expanded(child: debts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text('خطأ: \$e')),
          data: (list) => list.isEmpty
            ? const Center(child: Text('لا توجد ديون', style: TextStyle(color: Colors.grey)))
            : ListView.separated(padding: const EdgeInsets.fromLTRB(16,0,16,80), itemCount: list.length,
                separatorBuilder: (_,__) => const SizedBox(height: 8),
                itemBuilder: (_,i) {
                  final d = list[i];
                  final total = (d['totalAmount'] as num? ?? 0).toDouble();
                  final paid = (d['paidAmount'] as num? ?? 0).toDouble();
                  final remaining = total - paid;
                  final status = d['status'] as String? ?? 'active';
                  final debtId = d['id'] as String? ?? '';
                  return Card(child: ListTile(
                    title: Text(d['description']??'', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['customerName']??'', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: total > 0 ? (paid/total).clamp(0.0,1.0) : 0,
                          minHeight: 5, color: status.statusColor, backgroundColor: Colors.grey.withOpacity(0.2))),
                    ]),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: status.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(status.statusLabel, style: TextStyle(color: status.statusColor, fontSize: 11, fontWeight: FontWeight.w700))),
                      const SizedBox(height: 4),
                      Text(fmt.format(remaining) + ' ر.س',
                        style: TextStyle(color: remaining > 0 ? AppColors.warning : AppColors.accent, fontWeight: FontWeight.w800, fontSize: 12)),
                    ]),
                    onTap: () => context.push('/debts/\$debtId'),
                  ));
                }),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/debts/add'),
        icon: const Icon(Icons.add_card_outlined), label: const Text('دين جديد')),
    );
  }
}

class AddDebtScreen extends ConsumerWidget {
  final String? customerId;
  const AddDebtScreen({super.key, this.customerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('دين جديد')),
    body: const Center(child: Text('قريباً')),
  );
}

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الدين')),
    body: const Center(child: Text('قريباً')),
  );
}
