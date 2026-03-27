import 'package:flutter/material.dart';
import '../models/service_item.dart';

class ServiceCard extends StatelessWidget {

  const ServiceCard({super.key, required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: service.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: service.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    service.icon,
                    color: service.iconColor,
                    size: 30,
                  ),
                ),
              ),
            ),
            if (service.badgeCount != null && service.badgeCount! > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      service.badgeCount! > 9 ? '9+' : '${service.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          service.title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
