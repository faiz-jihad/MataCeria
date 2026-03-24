// lib/services/update_eye_refraction_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EyeRefractionService {
  // Gunakan baseUrl dari ApiConfig untuk ML service
  static String get baseUrl => ApiConfig.mlBaseUrl;
  
  // Cek kesehatan service
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.mlHealth}'),
      ).timeout(Duration(seconds: ApiConfig.connectionTimeout));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }
  
  // Dapatkan daftar kondisi mata
  Future<List<String>> getConditions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.mlConditions}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['conditions'] != null) {
          return List<String>.from(data['conditions']);
        }
      }
      return [];
    } catch (e) {
      print('Get conditions error: $e');
      return [];
    }
  }
  
  // Prediksi gambar
  Future<Map<String, dynamic>> predictImage(File imageFile) async {
    try {
      print('📤 Mengirim gambar ke ML service: $baseUrl${ApiConfig.mlPredict}');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConfig.mlPredict}'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Gagal memprediksi: $e');
    }
  }
  
  // Prediksi dengan dummy data (untuk testing)
  Future<Map<String, dynamic>> getDummyPrediction() async {
    // Simulasi delay
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'success': true,
      'predictions': [
        {'condition': 'myopia', 'confidence': 0.85, 'confidence_percent': '85.00%'},
        {'condition': 'astigmatism', 'confidence': 0.08, 'confidence_percent': '8.00%'},
        {'condition': 'normal eye', 'confidence': 0.04, 'confidence_percent': '4.00%'},
        {'condition': 'hyperopia', 'confidence': 0.02, 'confidence_percent': '2.00%'},
        {'condition': 'cataract', 'confidence': 0.01, 'confidence_percent': '1.00%'}
      ],
      'filename': 'test.jpg',
      'processed_at': DateTime.now().toIso8601String()
    };
  }
}