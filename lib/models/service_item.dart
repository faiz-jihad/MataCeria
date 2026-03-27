import 'package:flutter/material.dart';

class ServiceItem {

  ServiceItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.badgeCount,
    required this.onTap,
  });
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final int? badgeCount;
  final VoidCallback onTap;
}
