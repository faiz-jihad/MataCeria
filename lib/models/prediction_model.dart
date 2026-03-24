// lib/models/prediction_model.dart

import 'package:flutter/material.dart';
class Prediction {
  final int id;
  final String resultClass;
  final double confidence;
  final String imageUrl;
  final DateTime createdAt;

  Prediction({
    required this.id,
    required this.resultClass,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'],
      resultClass: json['result_class'],
      confidence: json['confidence'].toDouble(),
      imageUrl: json['image_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  String get className {
    switch (resultClass) {
      case 'Miopi':
        return 'Miopi (Rabun Jauh)';
      case 'Hipermetropi':
        return 'Hipermetropi (Rabun Dekat)';
      case 'Astigmatisme':
        return 'Silinder';
      case 'Normal':
        return 'Mata Normal';
      default:
        return resultClass;
    }
  }
  
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
  
  Color get color {
    switch (resultClass) {
      case 'Miopi':
        return Colors.green;
      case 'Hipermetropi':
        return Colors.orange;
      case 'Astigmatisme':
        return Colors.red;
      case 'Normal':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}