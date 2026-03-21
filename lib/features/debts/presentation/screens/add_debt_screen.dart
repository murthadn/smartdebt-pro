
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddDebtScreen({super.key, this.customerId});
  @override
  ConsumerState<AddDebtScreen> createState() => _State();
}
class _State extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _firstPayCtrl = TextEditingController(text: '0');
  final _countCtrl = TextEditingController(text: '1');
  String? _customerId;
  String? _customerName;
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر العميل أولاً')));
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(firebaseServiceProvider);
      final total = double.parse(_totalCtrl.text);
      final firstPay = double.tryParse(_firstPayCtrl.text) ?? 0;
      final count = int.tryParse(_countCtrl.text) ?? 1;
      final code = 'D-\${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final debtId = await service.add('debts', {
        'customerId': _customerId,
        'customerName': _customerName,
        'code': code,
        'description': _descCtrl.text.trim(),
        'totalAmount': total,
        'paidAmount': firstPay,
        'firstPayment': firstPay,
        'startDate': _startDate.toIso8601String(),
        'installmentsCount': count,
        'installmentAmount': count > 0 ? (total - firstPay) / count : 0,
        'installmentPeriod': _period,
        'status': 'active',
        'isDeleted': false,
      });
      await service.generateInstallments(
        debtId: debtId, customerId: _customerId!,
        totalAmount: total, firstPayment: firstPay,
        count: count, period: _period, startDate: _startDate,
      );
      await service.updateCustomerTotals(_customerId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الدين ✅'), backgroundColor: AppColors.accent));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('دين جديد')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(_customerName ?? 'اختر العميل *', style: TextStyle(color: _customerId == null ? Colors.grey : null)),
        trailing: const Icon(Icons.chevron_left),
        onTap: _pickCustomer,
      )),
      const SizedBox(height: 12),
      TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'وصف الدين *', prefixIcon: Icon(Icons.description_outlined)),
        validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _totalCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'المبلغ الكلي *', prefixIcon: Icon(Icons.attach_money)),
          validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null)),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: _firstPayCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الدفعة الأولى', prefixIcon: Icon(Icons.payment)))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _countCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'عدد الأقساط', prefixIcon: Icon(Icons.calendar_month_outlined)))),
        const SizedBox(width: 12),
        Expanded(child: DropdownButtonFormField<String>(value: _period,
          decoration: const InputDecoration(labelText: 'الفترة', prefixIcon: Icon(Icons.repeat)),
          items: const [
            DropdownMenuItem(value: 'monthly', child: Text('شهري')),
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
          ],
          onChanged: (v) => setState(() => _period = v!))),
      ]),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('إنشاء الدين')),
      const SizedBox(height: 40),
    ])),
  );

  Future<void> _pickCustomer() async {
    final customers = await ref.read(firebaseServiceProvider).getList('customers', filters: {'status': 'active'});
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String,dynamic>>(context: context,
      builder: (_) => ListView.builder(itemCount: customers.length,
        itemBuilder: (_,i) => ListTile(
          title: Text(customers[i]['name']??''),
          subtitle: Text(customers[i]['phone']??''),
          leading: CircleAvatar(child: Text((customers[i]['name'] as String? ?? '?').characters.first)),
          onTap: () => Navigator.pop(context, customers[i]))));
    if (result != null) setState(() { _customerId = result['id']; _customerName = result['name']; });
  }
}
