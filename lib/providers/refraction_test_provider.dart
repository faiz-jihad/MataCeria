import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum TestStatus { calibration, ready, testing, finished }

class SnellenRow {

  SnellenRow({required this.distanceRef, required this.letters});
  final int distanceRef; 
  final String letters;
}

class RefractionTestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  TestStatus _testStatus = TestStatus.calibration;
  TestStatus get testStatus => _testStatus;

  double _focalLength = 500; 
  bool _isCalibrated = false;
  bool get isCalibrated => _isCalibrated;

  double _currentDistanceCm = 0;
  double get currentDistanceCm => _currentDistanceCm;

  // Real-time smoothing
  final List<double> _smoothingHistory = [];
  static const int _historySize = 5;

  // Full-Session History for AI
  final List<double> _sessionDistanceHistory = [];

  // Calibration averaging
  final List<double> _calibrationPixelIpds = [];

  // ... (rest of states)
  Rect? _faceBoundingBox;
  Rect? get faceBoundingBox => _faceBoundingBox;

  double _pixelIpd = 0;
  double get pixelIpd => _pixelIpd;

  String? _aiResultCategory;
  String? get aiResultCategory => _aiResultCategory;

  double? _aiConfidence;
  double? get aiConfidence => _aiConfidence;

  bool _isProcessingAI = false;
  bool get isProcessingAI => _isProcessingAI;

  bool _isDetectingRemote = false;
  bool get isDetectingRemote => _isDetectingRemote;

  // New AI Enhanced fields
  String? _aiRecommendation;
  String? get aiRecommendation => _aiRecommendation;

  bool _aiActionRequired = false;
  bool get aiActionRequired => _aiActionRequired;

  bool _aiCanConsultChatbot = false;
  bool get aiCanConsultChatbot => _aiCanConsultChatbot;

  String? _aiVisualAcuity;
  String? get aiVisualAcuity => _aiVisualAcuity;

  double? _aiSnellenDecimal;
  double? get aiSnellenDecimal => _aiSnellenDecimal;

  int _countdown = 0;
  int get countdown => _countdown;

  final List<double> _responseTimes = [];
  DateTime? _lastRowShownTime;

  // Snellen Chart Data
  final List<SnellenRow> _snellenRows = [
    SnellenRow(distanceRef: 200, letters: 'E'),
    SnellenRow(distanceRef: 100, letters: 'F P'),
    SnellenRow(distanceRef: 70, letters: 'T O Z'),
    SnellenRow(distanceRef: 50, letters: 'L P E D'),
    SnellenRow(distanceRef: 40, letters: 'P E C F D'),
    SnellenRow(distanceRef: 30, letters: 'E D F C Z P'),
    SnellenRow(distanceRef: 25, letters: 'F E L O P Z D'),
    SnellenRow(distanceRef: 20, letters: 'D E F P O T E C'),
    SnellenRow(distanceRef: 15, letters: 'L E F O D P C T'),
    SnellenRow(distanceRef: 10, letters: 'F D P L T C E O'),
  ];
  List<SnellenRow> get snellenRows => _snellenRows;

  int _currentRowIndex = 0;
  int get currentRowIndex => _currentRowIndex;
  SnellenRow get currentRow => _snellenRows[_currentRowIndex];

  int _missedChars = 0;
  int get missedChars => _missedChars;

  int _smallestRowRead = 200; 
  int get smallestRowRead => _smallestRowRead;

  final double realIpdMm = 63.0; 

  void updateDistance(Face face) {
    if (face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null) {
      final leftEyeX = face.landmarks[FaceLandmarkType.leftEye]!.position.x.toDouble();
      final leftEyeY = face.landmarks[FaceLandmarkType.leftEye]!.position.y.toDouble();
      final rightEyeX = face.landmarks[FaceLandmarkType.rightEye]!.position.x.toDouble();
      final rightEyeY = face.landmarks[FaceLandmarkType.rightEye]!.position.y.toDouble();

      _processPixelIpd((leftEyeX - rightEyeX), (leftEyeY - rightEyeY), face.boundingBox);
    } else {
        _faceBoundingBox = null;
        notifyListeners();
    }
  }

  Future<void> updateDistanceRemote(String imageBase64) async {
    _isDetectingRemote = true;
    notifyListeners();

    try {
      final result = await _apiService.detectFaceDistance(imageBase64);
      
      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final faceFound = data['face_found'] ?? data['found'] ?? (data['eye_landmarks'] != null);
        final landmarks = data['eye_landmarks'] ?? data['landmarks'];

        if (faceFound && landmarks != null) {
           final left = landmarks['left_eye'] ?? landmarks['left'];
           final right = landmarks['right_eye'] ?? landmarks['right'];
           
           if (left is List && right is List) {
              _processPixelIpd(
                left[0].toDouble() - right[0].toDouble(),
                left[1].toDouble() - right[1].toDouble(),
                null
              );
           }
        } else {
           _faceBoundingBox = null;
           notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error in updateDistanceRemote: $e');
    } finally {
      _isDetectingRemote = false;
      notifyListeners();
    }
  }

  void startCountdown(VoidCallback onFinished) {
    _countdown = 3;
    notifyListeners();
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _countdown--;
      notifyListeners();
      if (_countdown <= 0) {
        onFinished();
        return false;
      }
      return true;
    });
  }

  void updateDistanceLocally(double dx, double dy, [Rect? bbox]) {
    _processPixelIpd(dx, dy, bbox);
  }

  void _processPixelIpd(double dx, double dy, Rect? bbox) {
    final pixelIpd = sqrt(dx * dx + dy * dy);
    _pixelIpd = pixelIpd;
    _faceBoundingBox = bbox;

    if (_testStatus == TestStatus.calibration) {
      _calibrationPixelIpds.add(pixelIpd);
      if (_calibrationPixelIpds.length > 20) _calibrationPixelIpds.removeAt(0);
      
      final tempDist = (_focalLength * realIpdMm) / pixelIpd;
      _currentDistanceCm = tempDist / 10.0;
    } else {
      final rawDistMm = (_focalLength * realIpdMm) / pixelIpd;
      final rawDistCm = rawDistMm / 10.0;
      
      // Smoothing for UI
      _smoothingHistory.add(rawDistCm);
      if (_smoothingHistory.length > _historySize) _smoothingHistory.removeAt(0);
      _currentDistanceCm = _smoothingHistory.reduce((a, b) => a + b) / _smoothingHistory.length;
      
      // Recording for AI result accuracy if test is active
      if (_testStatus == TestStatus.testing) {
        _sessionDistanceHistory.add(rawDistCm);
      }
    }
    notifyListeners();
  }

  void finishCalibration() {
    if (_calibrationPixelIpds.isNotEmpty) {
      final avgPixelIpd = _calibrationPixelIpds.reduce((a, b) => a + b) / _calibrationPixelIpds.length;
      _focalLength = (400.0 * avgPixelIpd) / realIpdMm;
      _isCalibrated = true;
      _testStatus = TestStatus.ready;
      notifyListeners();
    }
  }

  void startTest() {
    _testStatus = TestStatus.testing;
    _currentRowIndex = 0;
    _missedChars = 0;
    _smallestRowRead = 200;
    _responseTimes.clear();
    _lastRowShownTime = DateTime.now();
    _smoothingHistory.clear();
    _sessionDistanceHistory.clear();
    notifyListeners();
  }

  void submitRowResult(int errors) {
    if (_lastRowShownTime != null) {
      _responseTimes.add(DateTime.now().difference(_lastRowShownTime!).inMilliseconds.toDouble() / 1000.0);
    }
    
    _missedChars += errors;
    final charsInRow = currentRow.letters.replaceAll(' ', '').length;
    
    if (errors <= charsInRow / 2) {
      _smallestRowRead = currentRow.distanceRef;
      if (_currentRowIndex < _snellenRows.length - 1) {
        _currentRowIndex++;
        _lastRowShownTime = DateTime.now();
      } else {
        _testStatus = TestStatus.finished;
      }
    } else {
        _testStatus = TestStatus.finished;
    }
    notifyListeners();
  }

  Future<void> processAIResult({
    required String imageBase64,
    required String deviceInfo,
    double screenPpi = 441.0, 
  }) async {
    _isProcessingAI = true;
    notifyListeners();

    try {
      final totalTime = _responseTimes.isEmpty ? 0 : _responseTimes.reduce((a, b) => a + b);
      final avgTime = _responseTimes.isEmpty ? 0 : totalTime / _responseTimes.length;
      
      // Calculate real average from session history
      var avgDistance = _sessionDistanceHistory.isEmpty 
          ? (_currentDistanceCm > 0 ? _currentDistanceCm : 40.0)
          : _sessionDistanceHistory.reduce((a, b) => a + b) / _sessionDistanceHistory.length;
          
      // Defensive checks for NaN/Infinity to prevent JSON encoding errors
      if (avgDistance.isNaN || avgDistance.isInfinite) avgDistance = 40.0;
      var safeAvgTime = avgTime;
      if (safeAvgTime.isNaN || safeAvgTime.isInfinite) safeAvgTime = 1.0;

      final snellenData = {
        'avg_distance_cm': avgDistance,
        'smallest_row_read': _smallestRowRead,
        'missed_chars': _missedChars,
        'response_time': safeAvgTime,
      };

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('access_token');

      final result = await _apiService.postAIRefractionAI(
        imageBase64: imageBase64,
        snellenData: snellenData,
        userId: userId ?? token, 
        screenPpi: screenPpi, 
      );

      if (result['success']) {
        final data = result['data'];
        debugPrint('REFRACTION_DEBUG: Raw Data from Backend: $data');
        final results = data['results'] ?? data; 
        
        _aiResultCategory = results['predicted_class'] ?? 
                            results['condition_category'] ?? 
                            results['diagnosis'] ?? 
                            data['kategori'] ?? 
                            'Normal';

        _aiRecommendation = results['recommendation'] ?? results['saran'];
        _aiActionRequired = results['action_required'] ?? (_aiResultCategory != 'Normal');
        _aiCanConsultChatbot = results['can_consult_chatbot'] ?? true;
        _aiVisualAcuity = results['visual_acuity'] ?? results['tajam_penglihatan'];
        _aiSnellenDecimal = (results['snellen_decimal'] as num?)?.toDouble() ?? (results['decimal'] as num?)?.toDouble();

        final dynamic confidenceValue = results['confidence'] ?? data['confidence'];
        if (confidenceValue != null) {
          if (confidenceValue is String) {
             _aiConfidence = double.tryParse(confidenceValue.replaceAll('%', '')) ?? 0.0;
          } else if (confidenceValue is num) {
             _aiConfidence = confidenceValue.toDouble();
             if (_aiConfidence! <= 1.0) _aiConfidence = _aiConfidence! * 100;
          }
        }
      } else {
         _aiResultCategory = "Error: ${result['message']}";
      }
    } catch (e) {
      _aiResultCategory = 'Error: $e';
    } finally {
      _isProcessingAI = false;
      notifyListeners();
    }
  }

  void resetTest() {
    _currentRowIndex = 0;
    _testStatus = TestStatus.calibration;
    _isCalibrated = false;
    _currentDistanceCm = 0;
    _smoothingHistory.clear();
    _sessionDistanceHistory.clear();
    _missedChars = 0;
    _responseTimes.clear();
    _aiResultCategory = null;
    _aiConfidence = null;
    _aiRecommendation = null;
    _aiActionRequired = false;
    _aiCanConsultChatbot = false;
    _aiVisualAcuity = null;
    _aiSnellenDecimal = null;
    notifyListeners();
  }
}
