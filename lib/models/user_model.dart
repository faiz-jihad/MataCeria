class User {

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.age,
    this.gender,
    this.education,
    this.occupation,
    this.visionType,
    this.visionConcerns,
    this.allergies,
    this.medicalHistory,
    this.totalDetections,
    this.totalConsultations,
    this.createdAt,
    this.token,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['nama_lengkap'] ?? json['name'] ?? 'Pengguna',
      email: json['email'],
      phone: json['phone'],
      age: json['umur'],
      gender: json['kelamin'],
      education: json['jenjang_pendidikan'],
      occupation: json['status_pekerjaan'],
      visionType: json['vision_type'],
      visionConcerns: json['vision_concerns'] != null
          ? List<String>.from(json['vision_concerns'])
          : null,
      allergies: json['allergies'],
      medicalHistory: json['medical_history'],
      totalDetections: json['total_detections'],
      totalConsultations: json['total_consultations'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      token: json['token'],
      role: json['role'] ?? 'user',
    );
  }
  final int id;
  final String name;
  final String email;
  final String? phone;
  final int? age;
  final String? gender;
  final String? education;
  final String? occupation;
  final String? visionType;
  final List<String>? visionConcerns;
  final String? allergies;
  final String? medicalHistory;
  final int? totalDetections;
  final int? totalConsultations;
  final DateTime? createdAt;
  final String? token;
  final String? role;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'umur': age,
      'kelamin': gender,
      'jenjang_pendidikan': education,
      'status_pekerjaan': occupation,
      'vision_type': visionType,
      'vision_concerns': visionConcerns,
      'allergies': allergies,
      'medical_history': medicalHistory,
      'total_detections': totalDetections,
      'total_consultations': totalConsultations,
      'created_at': createdAt?.toIso8601String(),
      'role': role,
    };
  }
}
