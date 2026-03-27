import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationSheet extends StatelessWidget {

  const NotificationSheet({
    super.key,
    required this.unreadCount,
    required this.onReadAll,
  });
  final int unreadCount;
  final VoidCallback onReadAll;

  static void show({
    required BuildContext context,
    required int unreadCount,
    required VoidCallback onReadAll,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationSheet(
        unreadCount: unreadCount,
        onReadAll: onReadAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      onReadAll();
                      Navigator.pop(context);
                    },
                    child: const Text('Hapus Semua', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: apiService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final type = n['type'] ?? 'info';
                    
                    return _buildNotificationItem(n, type);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> n, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: type == 'alert' ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            type == 'alert' ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: type == 'alert' ? Colors.red.shade600 : Colors.blue.shade600,
          ),
        ),
        title: Text(
          n['title'] ?? 'Pemberitahuan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n['message'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              n['time'] ?? 'Tadi',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi baru',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Kami akan mengabari jika ada info penting.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
