// lib/models/prediction_model.dart

import 'package:flutter/material.dart';
import '../config/api_config.dart';
class Prediction {

  Prediction({
    required this.id,
    required this.resultClass,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
    this.visualAcuity,
    this.snellenDecimal,
    this.recommendation,
    this.actionRequired = false,
    this.canConsultChatbot = false,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    final results = json['results'] ?? {};
    
    // Robust parsing for V2 backend fields
    final String rClass = results['predicted_class'] ?? 
                         json['predicted_class'] ?? 
                         results['condition_category'] ??
                         json['condition_category'] ??
                         json['result_class'] ?? 
                         json['class_name'] ?? 
                         'Unknown';
                         
    double conf = (results['confidence'] ?? json['confidence'] ?? 0.0).toDouble();
    if (conf > 0 && conf <= 1.0) conf = conf * 100;

    return Prediction(
      id: json['id'] ?? 0,
      resultClass: rClass,
      confidence: conf / 100, // Keep internally as 0-1
      imageUrl: json['image_url'] ?? results['image_url'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      visualAcuity: results['visual_acuity'] ?? json['visual_acuity'] ?? results['tajam_penglihatan'],
      snellenDecimal: (results['snellen_decimal'] ?? json['snellen_decimal'] ?? json['decimal'] as num?)?.toDouble(),
      recommendation: results['recommendation'] ?? json['recommendation'] ?? results['saran'],
      actionRequired: results['action_required'] ?? json['action_required'] ?? (rClass != 'Normal'),
      canConsultChatbot: results['can_consult_chatbot'] ?? json['can_consult_chatbot'] ?? false,
    );
  }
  final int id;
  final String resultClass;
  final double confidence;
  final String imageUrl;
  final DateTime createdAt;

  final String? visualAcuity;
  final double? snellenDecimal;
  final String? recommendation;
  final bool actionRequired;
  final bool canConsultChatbot;

  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    // Use the root baseUrl (without /api/v1 prefix) for static media
    return '${ApiConfig.baseUrl}$imageUrl';
  }
  
  String get className {
    switch (resultClass) {
      case 'Normal':
        return 'Mata Normal';
      case 'Mild Impairment':
        return 'Gangguan Ringan';
      case 'Myopia':
      case 'Miopi':
        return 'Miopi (Rabun Jauh)';
      case 'Severe Impairment':
        return 'Gangguan Berat';
      case 'Hipermetropi':
        return 'Hipermetropi (Rabun Dekat)';
      case 'Astigmatisme':
        return 'Silinder';
      default:
        return resultClass;
    }
  }
  
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  
  Color get color {
    switch (resultClass) {
      case 'Normal':
        return Colors.blue;
      case 'Mild Impairment':
        return Colors.green;
      case 'Myopia':
      case 'Miopi':
        return Colors.orange;
      case 'Severe Impairment':
      case 'Astigmatisme':
        return Colors.red;
      case 'Hipermetropi':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}