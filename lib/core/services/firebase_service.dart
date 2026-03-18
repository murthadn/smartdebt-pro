
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

class FirebaseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _cid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _col(String path) =>
      _db.collection('companies/\$_cid/\$path');

  DocumentReference<Map<String, dynamic>> _doc(String path, String id) =>
      _db.doc('companies/\$_cid/\$path/\$id');

  Future<String> add(String col, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = _auth.currentUser?.uid;
    data['isDeleted'] = data['isDeleted'] ?? false;
    final ref = await _col(col).add(data);
    return ref.id;
  }

  Future<void> update(String col, String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _doc(col, id).update(data);
  }

  Future<void> delete(String col, String id) async {
    await _doc(col, id).update({'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp()});
  }

  Future<Map<String, dynamic>?> get(String col, String id) async {
    final snap = await _doc(col, id).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...snap.data()!};
  }

  Stream<List<Map<String, dynamic>>> stream(String col, {
    List<List<dynamic>> where = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _col(col).where('isDeleted', isNotEqualTo: true);
    for (final w in where) { q = q.where(w[0], isEqualTo: w[1]); }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getList(String col, {
    Map<String, dynamic> filters = const {},
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> q = _col(col).where('isDeleted', isNotEqualTo: true);
    filters.forEach((k, v) { if (v != null) q = q.where(k, isEqualTo: v); });
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  WriteBatch batch() => _db.batch();

  Future<String> addPayment(Map<String, dynamic> data) async {
    final batch = _db.batch();
    final payRef = _col('payments').doc();
    final debtRef = _doc('debts', data['debtId']);
    final amount = (data['amount'] as num).toDouble();
    batch.set(payRef, {...data, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(), 'isDeleted': false});
    batch.update(debtRef, {'paidAmount': FieldValue.increment(amount), 'updatedAt': FieldValue.serverTimestamp()});
    if (data['installmentId'] != null) {
      batch.update(_doc('installments', data['installmentId']), {'paidAmount': FieldValue.increment(amount), 'status': 'paid', 'paidDate': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    final receiptNo = 'R-\${DateTime.now().millisecondsSinceEpoch}';
    await payRef.update({'receiptNo': receiptNo});
    await updateCustomerTotals(data['customerId']);
    final debtSnap = await debtRef.get();
    final d = debtSnap.data()!;
    if ((d['paidAmount'] as num) >= (d['totalAmount'] as num)) {
      await debtRef.update({'status': 'completed'});
    }
    return payRef.id;
  }

  Future<void> updateCustomerTotals(String customerId) async {
    final debts = await getList('debts', filters: {'customerId': customerId});
    double totalDebt = 0, totalPaid = 0;
    for (final d in debts) {
      totalDebt += (d['totalAmount'] as num? ?? 0).toDouble();
      totalPaid += (d['paidAmount'] as num? ?? 0).toDouble();
    }
    await update('customers', customerId, {'totalDebt': totalDebt, 'totalPaid': totalPaid});
  }

  Future<void> generateInstallments({
    required String debtId, required String customerId,
    required double totalAmount, required double firstPayment,
    required int count, required String period, required DateTime startDate,
  }) async {
    if (count <= 0) return;
    final amount = (totalAmount - firstPayment) / count;
    final batch = _db.batch();
    for (int i = 1; i <= count; i++) {
      late DateTime due;
      if (period == 'monthly') due = DateTime(startDate.year, startDate.month + i, startDate.day);
      else if (period == 'weekly') due = startDate.add(Duration(days: 7 * i));
      else due = startDate.add(Duration(days: 30 * i));
      final ref = _col('installments').doc();
      batch.set(ref, {
        'debtId': debtId, 'customerId': customerId,
        'installmentNo': i, 'amount': double.parse(amount.toStringAsFixed(2)),
        'paidAmount': 0.0, 'dueDate': Timestamp.fromDate(due),
        'status': 'pending', 'createdAt': FieldValue.serverTimestamp(), 'isDeleted': false,
      });
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final results = await Future.wait([
      getList('customers', filters: {'status': 'active'}),
      getList('debts', filters: {'status': 'active'}),
      getList('debts', filters: {'status': 'late'}),
      getList('subscriptions', filters: {'status': 'active'}),
    ]);
    final customers = results[0]; final activeDebts = results[1];
    final lateDebts = results[2]; final activeSubs = results[3];
    double totalDebt = 0, totalPaid = 0, totalOverdue = 0;
    for (final d in [...activeDebts, ...lateDebts]) {
      totalDebt += (d['totalAmount'] as num? ?? 0).toDouble();
      totalPaid += (d['paidAmount'] as num? ?? 0).toDouble();
    }
    for (final d in lateDebts) { totalOverdue += ((d['totalAmount'] as num? ?? 0) - (d['paidAmount'] as num? ?? 0)).toDouble(); }
    final soon = now.add(const Duration(days: 7));
    final expiring = activeSubs.where((s) {
      try {
        final r = DateTime.parse(s['nextRenewal'] ?? '');
        return r.isBefore(soon);
      } catch (_) { return false; }
    }).length;
    return {
      'totalCustomers': customers.length, 'activeDebts': activeDebts.length,
      'lateDebts': lateDebts.length, 'activeSubscriptions': activeSubs.length,
      'expiringSubscriptions': expiring, 'totalDebtAmount': totalDebt,
      'totalCollected': totalPaid, 'totalOverdue': totalOverdue,
      'todayCollected': 0.0, 'todayPayments': 0,
    };
  }
}
