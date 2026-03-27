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
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      type: json['type'],
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