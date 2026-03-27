import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      if (type == 'detection') return Icons.camera_alt_rounded;
      if (type == 'consultation') return Icons.chat_bubble_rounded;
      return Icons.info_rounded;
    }

    Color getColor() {
      if (type == 'detection') return const Color(0xFFE0F2FE);
      if (type == 'consultation') return const Color(0xFFFEF3C7);
      return Colors.grey.shade100;
    }

    Color getIconColor() {
      if (type == 'detection') return const Color(0xFF2563EB);
      if (type == 'consultation') return const Color(0xFFF59E0B);
      return Colors.grey.shade600;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: getColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(getIcon(), color: getIconColor(), size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
