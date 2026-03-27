import 'package:flutter/material.dart';
import '../models/emergency_model.dart';

class EmergencyCard extends StatelessWidget {

  const EmergencyCard({
    super.key,
    required this.contact,
    required this.index,
    required this.onCall,
  });
  final EmergencyContact contact;
  final int index;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    Color getTypeColor() {
      switch (contact.type) {
        case 'hospital': return Colors.red;
        case 'clinic': return Colors.blue;
        case 'pharmacy': return Colors.green;
        default: return Colors.orange;
      }
    }

    final color = getTypeColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      contact.type == 'hospital'
                          ? Icons.local_hospital
                          : contact.type == 'clinic'
                              ? Icons.medical_services
                              : Icons.local_pharmacy,
                      size: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.phone, size: 10, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 10, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      contact.city ?? 'Jakarta',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
