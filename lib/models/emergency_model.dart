// lib/models/emergency_model.dart

class EmergencyContact {

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.city,
    required this.type,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['nama'] ?? 'Unknown',
      phone: json['phone'] ?? json['nomor_telepon'] ?? json['nomorTelepon'] ?? '-',
      address: json['address'],
      city: json['city'],
      type: json['type'] ?? json['category'] ?? json['kategori'] ?? 'hospital',
    );
  }
  final int id;
  final String name;
  final String phone;
  final String? address;
  final String? city;
  final String type;
  
  String get typeName {
    switch (type) {
      case 'hospital':
        return 'Rumah Sakit';
      case 'clinic':
        return 'Klinik';
      case 'pharmacy':
        return 'Apotek';
      case 'ambulance':
        return 'Ambulans';
      default:
        return type;
    }
  }
}