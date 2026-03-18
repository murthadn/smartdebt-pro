
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final notifsProvider = StreamProvider<List<Map<String,dynamic>>>((ref) =>
  ref.read(firebaseServiceProvider).stream('notifications', orderBy: 'createdAt', descending: true, limit: 50));

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notifsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات'), actions: [
        TextButton(onPressed: (){}, child: const Text('قراءة الكل', style: TextStyle(color: Colors.white, fontSize: 13))),
      ]),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: \$e')),
        data: (list) => list.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none_outlined, size: 72, color: Colors.grey),
              SizedBox(height: 12),
              Text('لا توجد تنبيهات', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_,__) => const SizedBox(height: 6),
              itemBuilder: (_,i) {
                final n = list[i];
                final isRead = n['isRead'] == true;
                return Card(child: ListTile(
                  leading: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(isRead ? 0.07 : 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.notifications, color: AppColors.primaryLight.withOpacity(isRead ? 0.4 : 1), size: 20)),
                  title: Text(n['title']??'', style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14)),
                  subtitle: n['body'] != null ? Text(n['body'], style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                  trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle)) : null,
                  onTap: () => ref.read(firebaseServiceProvider).update('notifications', n['id'], {'isRead': true}),
                ));
              }),
      ),
    );
  }
}
