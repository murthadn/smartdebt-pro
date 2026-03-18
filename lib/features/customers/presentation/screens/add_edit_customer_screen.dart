
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AddEditCustomerScreen({super.key, this.customerId});
  @override
  ConsumerState<AddEditCustomerScreen> createState() => _State();
}

class _State extends ConsumerState<AddEditCustomerScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _phone2 = TextEditingController();
  final _id = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  String _city = 'الرياض';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) _load();
  }

  Future<void> _load() async {
    final d = await ref.read(firebaseServiceProvider).get('customers', widget.customerId!);
    if (d != null && mounted) {
      _name.text = d['name']??''; _phone.text = d['phone']??'';
      _phone2.text = d['phone2']??''; _id.text = d['nationalId']??'';
      _address.text = d['address']??''; _notes.text = d['notes']??'';
      setState(() => _city = d['city']??'الرياض');
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final s = ref.read(firebaseServiceProvider);
      final data = {'name': _name.text.trim(), 'phone': _phone.text.trim(), 'phone2': _phone2.text.trim(), 'nationalId': _id.text.trim(), 'address': _address.text.trim(), 'city': _city, 'notes': _notes.text.trim(), 'status': 'active', 'isDeleted': false};
      if (widget.customerId != null) {
        await s.update('customers', widget.customerId!, data);
      } else {
        await s.add('customers', {...data, 'totalDebt': 0.0, 'totalPaid': 0.0, 'code': 'C-\${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'});
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✅'), backgroundColor: AppColors.accent)); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.customerId != null ? 'تعديل العميل' : 'إضافة عميل')),
    body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم الكامل *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الهاتف *', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => (v?.isEmpty??true) ? 'مطلوب' : null)),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: _phone2, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'هاتف ثانٍ', prefixIcon: Icon(Icons.phone_outlined)))),
      ]),
      const SizedBox(height: 12),
      TextFormField(controller: _id, decoration: const InputDecoration(labelText: 'رقم الهوية', prefixIcon: Icon(Icons.badge_outlined))),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _city, decoration: const InputDecoration(labelText: 'المدينة', prefixIcon: Icon(Icons.location_city_outlined)),
        items: ['الرياض','جدة','مكة المكرمة','المدينة المنورة','الدمام','الخبر','أبها','تبوك','أخرى'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _city = v!)),
      const SizedBox(height: 12),
      TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 12),
      TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(hintText: 'ملاحظات...', border: OutlineInputBorder())),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.customerId != null ? 'حفظ التعديلات' : 'إضافة العميل')),
      const SizedBox(height: 40),
    ])),
  );
}
