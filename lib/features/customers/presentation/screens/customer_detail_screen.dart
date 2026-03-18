
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final customerDetailProvider = FutureProvider.family<Map<String,dynamic>?, String>((ref, id) => ref.read(firebaseServiceProvider).get('customers', id));
final customerDebtsProvider = StreamProvider.family<List<Map<String,dynamic>>, String>((ref, id) => ref.read(firebaseServiceProvider).stream('debts', where: [['customerId', id]], orderBy: 'createdAt', descending: true));
final customerPaymentsProvider = StreamProvider.family<List<Map<String,dynamic>>, String>((ref, id) => ref.read(firebaseServiceProvider).stream('payments', where: [['customerId', id]], orderBy: 'paymentDate', descending: true, limit: 20));

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  ConsumerState<CustomerDetailScreen> createState() => _State();
}
class _State extends ConsumerState<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(customerDetailProvider(widget.customerId));
    final fmt = NumberFormat('#,##0.##', 'ar');
    return c.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e,_) => Scaffold(body: Center(child: Text('خطأ: \$e'))),
      data: (cust) {
        if (cust == null) return const Scaffold(body: Center(child: Text('غير موجود')));
        final name = cust['name'] as String? ?? '';
        final phone = cust['phone'] as String?;
        final total = (cust['totalDebt'] as num? ?? 0).toDouble();
        final paid = (cust['totalPaid'] as num? ?? 0).toDouble();
        final remaining = total - paid;
        final progress = total > 0 ? (paid/total).clamp(0.0,1.0) : 0.0;
        return Scaffold(
          appBar: AppBar(title: Text(name), actions: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/customers/\${widget.customerId}/edit')),
          ]),
          body: Column(children: [
            Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryLight])), child: Column(children: [
              Row(children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(name.isNotEmpty ? name.characters.first : '?', style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800)),
                  if (phone != null) Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _S(fmt.format(total), 'الكلي', Colors.white),
                _S(fmt.format(paid), 'المدفوع', const Color(0xFFA8E6CF)),
                _S(fmt.format(remaining), 'المتبقي', remaining > 0 ? const Color(0xFFFFD3B6) : const Color(0xFFA8E6CF)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: Colors.white24, color: Colors.white)),
            ])),
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              _Btn('دين جديد', Icons.add_card_outlined, AppColors.accent, () => context.push('/debts/add?customerId=\${widget.customerId}')),
              const SizedBox(width: 8),
              _Btn('دفعة', Icons.payments_outlined, AppColors.warning, () => context.push('/payments/add')),
              const SizedBox(width: 8),
              if (phone != null) _Btn('واتساب', Icons.chat_outlined, const Color(0xFF25D366), () { final n = phone.replaceAll(RegExp(r'[^0-9]'),''); launchUrl(Uri.parse('https://wa.me/\${n.startsWith('0') ? '966\${n.substring(1)}' : n}')); }),
            ])),
            TabBar(controller: _tabs, tabs: const [Tab(text: 'الديون'), Tab(text: 'الدفعات')]),
            Expanded(child: TabBarView(controller: _tabs, children: [
              _DebtsTab(customerId: widget.customerId, fmt: fmt),
              _PaysTab(customerId: widget.customerId, fmt: fmt),
            ])),
          ]),
        );
      },
    );
  }
  Widget _S(String v, String l, Color c) => Expanded(child: Column(children: [Text('\$v ر.س', style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center), Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center)]));
  Widget _Btn(String l, IconData icon, Color c, VoidCallback f) => Expanded(child: GestureDetector(onTap: f, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.3))), child: Column(children: [Icon(icon, color: c, size: 20), const SizedBox(height: 3), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700))]))));
}
class _DebtsTab extends ConsumerWidget {
  final String customerId; final NumberFormat fmt;
  const _DebtsTab({required this.customerId, required this.fmt});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(customerDebtsProvider(customerId)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,_) => Center(child: Text('خطأ: \$e')),
      data: (list) => list.isEmpty ? const Center(child: Text('لا توجد ديون', style: TextStyle(color: Colors.grey)))
        : ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
          itemBuilder: (_,i) {
            final d = list[i]; final status = d['status'] as String? ?? 'active';
            final total = (d['totalAmount'] as num? ?? 0).toDouble(); final paid = (d['paidAmount'] as num? ?? 0).toDouble();
            return Card(child: ListTile(
              title: Text(d['description']??'', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('\${d['code']??''} • \${d['installmentsCount']??1} قسط', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: total > 0 ? (paid/total).clamp(0.0,1.0) : 0, minHeight: 5, color: status.statusColor, backgroundColor: Colors.grey.withOpacity(0.2))),
              ]),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: status.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(status.statusLabel, style: TextStyle(color: status.statusColor, fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Text('\${fmt.format(total-paid)} ر.س', style: TextStyle(color: (total-paid) > 0 ? AppColors.warning : AppColors.accent, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
              onTap: () => context.push('/debts/\${d['id']}'),
            ));
          }),
    );
  }
}
class _PaysTab extends ConsumerWidget {
  final String customerId; final NumberFormat fmt;
  const _PaysTab({required this.customerId, required this.fmt});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(customerPaymentsProvider(customerId)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,_) => Center(child: Text('خطأ: \$e')),
      data: (list) => list.isEmpty ? const Center(child: Text('لا توجد دفعات', style: TextStyle(color: Colors.grey)))
        : ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length, separatorBuilder: (_,__) => const SizedBox(height: 6),
          itemBuilder: (_,i) {
            final p = list[i];
            return Card(child: ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_upward, color: AppColors.accent, size: 18)),
              title: Text('\${fmt.format(p['amount']??0)} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 15)),
              subtitle: Text(p['paymentDate']?.toString().substring(0,10)??'—', style: const TextStyle(fontSize: 12)),
            ));
          }),
    );
  }
}
