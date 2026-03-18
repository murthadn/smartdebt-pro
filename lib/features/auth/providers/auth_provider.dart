
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(() => AuthNotifier());

class AppUser {
  final String uid, companyId, name, email, role;
  final bool isActive;
  const AppUser({required this.uid, required this.companyId, required this.name, required this.email, required this.role, required this.isActive});
  bool get isAdmin => role == 'admin';
  bool get isManager => ['admin','manager'].contains(role);
  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(uid: uid, companyId: d['companyId']??'', name: d['name']??'', email: d['email']??'', role: d['role']??'employee', isActive: d['isActive']??true);
}

class AuthNotifier extends AsyncNotifier<AppUser?> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  @override
  Future<AppUser?> build() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _fetch(u.uid);
  }
  Future<AppUser?> _fetch(String uid) async {
    final s = await _db.collection('appUsers').doc(uid).get();
    if (!s.exists) return null;
    return AppUser.fromMap(uid, s.data()!);
  }
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final c = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final u = await _fetch(c.user!.uid);
      if (u == null) throw Exception('بيانات المستخدم غير موجودة');
      if (!u.isActive) throw Exception('الحساب موقوف');
      await _db.collection('appUsers').doc(c.user!.uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return u;
    });
  }
  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncData(null);
  }
}
