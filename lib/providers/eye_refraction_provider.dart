// lib/providers/eye_refraction_provider.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/eye_refraction_model.dart';

class EyeRefractionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  EyeRefractionResult? _result;
  bool _serviceHealthy = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  EyeRefractionResult? get result => _result;
  bool get serviceHealthy => _serviceHealthy;

  Future<bool> checkMLHealth() async {
    _serviceHealthy = await _apiService.checkMLHealth();
    notifyListeners();
    return _serviceHealthy;
  }

  Future<bool> detectEyeRefraction(XFile imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isHealthy = await checkMLHealth();
      if (!isHealthy) {
        throw Exception('ML Service tidak tersedia. Hubungi IT Rumah Sakit.');
      }
      
      final response = await _apiService.detectEyeRefraction(imageFile);
      
      if (response['success'] && response['data'] != null) {
        _result = EyeRefractionResult.fromJson(response['data']);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Data deteksi tidak valid';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetResult() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}