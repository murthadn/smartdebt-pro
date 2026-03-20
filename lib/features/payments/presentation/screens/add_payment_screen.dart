
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String? debtId;
  final String? installmentId;
  const AddPaymentScreen({super.key, this.debtId, this.installmentId});
  @override
  ConsumerState<AddPaymentScreen> createState() => _State();
}

class _State extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'cash';
  bool _saving = false;
  Map<String,dynamic>? _debt;

  @override
  void initState() {
    super.initState();
    if (widget.debtId != null) _loadDebt();
  }

  Future<void> _loadDebt() async {
    final d = await ref.read(firebaseServiceProvider).get('debts', widget.debtId!);
    if (mounted) setState(() => _debt = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_debt == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الدين أولاً'))); return; }
    setState(() => _saving = true);
    try {
      await ref.read(firebaseServiceProvider).addPayment({
        'debtId': widget.debtId,
        'installmentId': widget.installmentId,
        'customerId': _debt!['customerId'],
        'customerName': _debt!['customerName'],
        'amount': double.parse(_amountCtrl.text),
        'paymentMethod': _method,
        'paymentDate': DateTime.now().toIso8601String(),
        'notes': _notesCtrl.text.trim(),
        'isDeleted': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة ✅'), backgroundColor: AppColors.accent));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'ar');
    final remaining = _debt != null ? ((_debt!['totalAmount'] as num? ?? 0) - (_debt!['paidAmount'] as num? ?? 0)).toDouble() : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دفعة')),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_debt != null) Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_debt!['customerName']??'', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(_debt!['description']??'', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text('المتبقي: \${fmt.format(remaining)} ر.س', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
          ])),
        TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ الدفعة (ر.س) *', prefixIcon: Icon(Icons.attach_money)),
          validator: (v) { if (v?.isEmpty??true) return 'المبلغ مطلوب'; if ((double.tryParse(v!)??0)<=0) return 'مبلغ غير صالح'; return null; }),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _method,
          decoration: const InputDecoration(labelText: 'طريقة الدفع', prefixIcon: Icon(Icons.payment)),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('نقداً')),
            DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي')),
            DropdownMenuItem(value: 'check', child: Text('شيك')),
            DropdownMenuItem(value: 'card', child: Text('بطاقة')),
          ],
          onChanged: (v) => setState(() => _method = v!)),
        const SizedBox(height: 12),
        TextFormField(controller: _notesCtrl, maxLines: 2,
          decoration: const InputDecoration(hintText: 'ملاحظات...', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تسجيل الدفعة')),
        const SizedBox(height: 40),
      ])),
    );
  }
}
