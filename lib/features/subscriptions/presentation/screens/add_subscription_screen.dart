
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddSubscriptionScreen({super.key, this.customerId});
  @override
  ConsumerState<AddSubscriptionScreen> createState() => _State();
}
class _State extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _customerId, _customerName;
  String _period = 'monthly';
  bool _saving = false;

  @override
  void initState() { super.initState(); _customerId = widget.customerId; }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر العميل'))); return; }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      DateTime next;
      if (_period == 'monthly') next = DateTime(now.year, now.month + 1, now.day);
      else if (_period == 'yearly') next = DateTime(now.year + 1, now.month, now.day);
      else next = now.add(const Duration(days: 7));
      await ref.read(firebaseServiceProvider).add('subscriptions', {
        'customerId': _customerId, 'customerName': _customerName,
        'planName': _planCtrl.text.trim(),
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'period': _period,
        'startDate': now.toIso8601String(),
        'nextRenewal': next.toIso8601String(),
        'autoRenew': true, 'status': 'active', 'isDeleted': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الاشتراك ✅'), backgroundColor: AppColors.accent));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اشتراك جديد')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.person_outline),
        title: Text(_customerName ?? 'اختر العميل *', style: TextStyle(color: _customerId == null ? Colors.grey : null)),
        trailing: const Icon(Icons.chevron_left), onTap: _pickCustomer)),
      const SizedBox(height: 12),
      TextFormField(controller: _planCtrl, decoration: const InputDecoration(labelText: 'اسم الباقة *', prefixIcon: Icon(Icons.subscriptions_outlined)),
        validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'المبلغ (ر.س) *', prefixIcon: Icon(Icons.attach_money)),
          validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null)),
        const SizedBox(width: 12),
        Expanded(child: DropdownButtonFormField<String>(value: _period,
          decoration: const InputDecoration(labelText: 'الفترة', prefixIcon: Icon(Icons.repeat)),
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
            DropdownMenuItem(value: 'monthly', child: Text('شهري')),
            DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
          ],
          onChanged: (v) => setState(() => _period = v!))),
      ]),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('إنشاء الاشتراك')),
      const SizedBox(height: 40),
    ])),
  );

  Future<void> _pickCustomer() async {
    final customers = await ref.read(firebaseServiceProvider).getList('customers', filters: {'status': 'active'});
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String,dynamic>>(context: context,
      builder: (_) => ListView.builder(itemCount: customers.length,
        itemBuilder: (_,i) => ListTile(
          title: Text(customers[i]['name']??''), subtitle: Text(customers[i]['phone']??''),
          leading: CircleAvatar(child: Text((customers[i]['name'] as String? ?? '?').characters.first)),
          onTap: () => Navigator.pop(context, customers[i]))));
    if (result != null) setState(() { _customerId = result['id']; _customerName = result['name']; });
  }
}
