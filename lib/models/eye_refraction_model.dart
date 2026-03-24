// lib/models/eye_refraction_model.dart

import 'package:flutter/material.dart';

class EyeRefractionPrediction {
  final String condition;
  final double confidence;
  final String confidencePercent;

  EyeRefractionPrediction({
    required this.condition,
    required this.confidence,
    required this.confidencePercent,
  });

  factory EyeRefractionPrediction.fromJson(Map<String, dynamic> json) {
    return EyeRefractionPrediction(
      condition: json['condition'],
      confidence: json['confidence'].toDouble(),
      confidencePercent: json['confidence_percent'] ?? 
          '${(json['confidence'] * 100).toStringAsFixed(1)}%',
    );
  }

  String get conditionInIndonesian {
    final Map<String, String> translation = {
      'myopia': 'Rabun Jauh (Miopi)',
      'hyperopia': 'Rabun Dekat (Hipermetropi)',
      'astigmatism': 'Silinder (Astigmatisme)',
      'presbyopia': 'Mata Tua (Presbiopi)',
      'cataract': 'Katarak',
      'normal eye': 'Mata Normal',
      'healthy eye': 'Mata Sehat',
    };
    return translation[condition.toLowerCase()] ?? condition;
  }

  Color get color {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('myopia') || lowerCondition.contains('hyperopia') || lowerCondition.contains('astigmatism')) {
      return Colors.orange;
    } else if (lowerCondition.contains('cataract') || lowerCondition.contains('glaucoma')) {
      return Colors.red;
    } else if (lowerCondition.contains('normal') || lowerCondition.contains('healthy')) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
}

class EyeRefractionResult {
  final List<EyeRefractionPrediction> predictions;
  final DateTime processedAt;

  EyeRefractionResult({
    required this.predictions,
    required this.processedAt,
  });

  factory EyeRefractionResult.fromJson(Map<String, dynamic> json) {
    var rawPredictions = json['predictions'];
    List<EyeRefractionPrediction> predictionsList = [];
    
    if (rawPredictions is List) {
      predictionsList = rawPredictions
          .map((p) => EyeRefractionPrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return EyeRefractionResult(
      predictions: predictionsList,
      processedAt: DateTime.parse(json['processed_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  EyeRefractionPrediction get topPrediction => predictions.first;
}