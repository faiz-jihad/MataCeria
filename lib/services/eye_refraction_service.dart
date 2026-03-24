// lib/services/eye_refraction_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class EyeRefractionService {
  static final String baseUrl = ApiConfig.fullBaseUrl;
  
  Future<Map<String, dynamic>> predictEyeRefraction(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConfig.uploadTest}'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      
      if (response.statusCode == 200) {
        return json.decode(responseData.body);
      } else {
        throw Exception('Failed to predict: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  Future<List<String>> getConditions({int page = 1}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/conditions?page=$page&per_page=50'),
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return List<String>.from(data['conditions']);
      }
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}