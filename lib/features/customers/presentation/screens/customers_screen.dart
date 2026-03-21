import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final customerFilterProvider = StateProvider<String>((ref) => 'all');
final customerSearchProvider = StateProvider<String>((ref) => '');
final customersStreamProvider = StreamProvider<List<Map<String,dynamic>>>(
  (ref) => ref.read(firebaseServiceProvider).stream('customers', orderBy: 'name'));
final filteredCustomersProvider = Provider<AsyncValue<List<Map<String,dynamic>>>>((ref) {
  final filter = ref.watch(customerFilterProvider);
  final search = ref.watch(customerSearchProvider).toLowerCase();
  return ref.watch(customersStreamProvider).whenData((list) => list.where((c) {
    final ms = filter == 'all' || c['status'] == filter;
    final mq = search.isEmpty ||
      (c['name'] as String? ?? '').toLowerCase().contains(search) ||
      (c['phone'] as String? ?? '').contains(search);
    return ms && mq;
  }).toList());
});

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});
  @override
  ConsumerState<CustomersScreen> createState() => _State();
}

class _State extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(filteredCustomersProvider);
    final filter = ref.watch(customerFilterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء'), actions: [
        IconButton(icon: const Icon(Icons.person_add_outlined),
          onPressed: () => context.push('/customers/add')),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0), child: TextField(
          controller: _search,
          onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'البحث...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _search.clear();
                  ref.read(customerSearchProvider.notifier).state = '';
                })
              : null,
          ),
        )),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final f in ['all','active','inactive','blocked'])
              Padding(padding: const EdgeInsets.only(left: 8), child: FilterChip(
                label: Text(const {'all':'الكل','active':'فعال','inactive':'غير فعال','blocked':'محظور'}[f]!),
                selected: filter == f,
                onSelected: (_) => ref.read(customerFilterProvider.notifier).state = f,
              )),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: customers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text('خطأ: $e')),
          data: (list) => list.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.people_outline, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Text('لا يوجد عملاء', style: TextStyle(color: Colors.grey)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16,0,16,80),
                itemCount: list.length,
                separatorBuilder: (_,__) => const SizedBox(height: 8),
                itemBuilder: (_,i) => _CustomerCard(customer: list[i]),
              ),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/add'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('إضافة عميل'),
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Map<String,dynamic> customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = customer['name'] as String? ?? '';
    final status = customer['status'] as String? ?? 'active';
    final remaining = ((customer['totalDebt'] as num? ?? 0) - (customer['totalPaid'] as num? ?? 0)).toDouble();
    final cid = customer['id'] as String? ?? '';

    return Slidable(
      endActionPane: ActionPane(motion: const DrawerMotion(), children: [
        SlidableAction(
          onPressed: (_) => context.push('/customers/$cid/edit'),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          icon: Icons.edit_outlined,
          label: 'تعديل',
          borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        ),
        SlidableAction(
          onPressed: (_) async {
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('حذف'),
              content: Text('حذف "$name"؟'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('حذف')),
              ],
            ));
            if (ok == true) await ref.read(firebaseServiceProvider).delete('customers', cid);
          },
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          icon: Icons.delete_outline,
          label: 'حذف',
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
        ),
      ]),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/customers/$cid'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(
                name.isNotEmpty ? name.characters.first : '?',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.statusLabel, style: TextStyle(color: status.statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
              if (customer['phone'] != null)
                Text(customer['phone'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (remaining > 0 ? AppColors.warning : AppColors.accent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'متبقي: ${remaining.toStringAsFixed(0)} ر.س',
                  style: TextStyle(color: remaining > 0 ? AppColors.warning : AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ])),
            const Icon(Icons.chevron_left, color: Colors.grey),
          ])),
        ),
      ),
    );
  }
}
