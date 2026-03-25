import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';

enum TestStatus { calibration, ready, testing, finished }

class SnellenRow {
  final int distanceRef; 
  final String letters;

  SnellenRow({required this.distanceRef, required this.letters});
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
  final List<double> _distanceHistory = [];
  static const int _historySize = 5;

  // Calibration averaging
  final List<double> _calibrationPixelIpds = [];

  // AI & Analytics States
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
      final double leftEyeX = face.landmarks[FaceLandmarkType.leftEye]!.position.x.toDouble();
      final double leftEyeY = face.landmarks[FaceLandmarkType.leftEye]!.position.y.toDouble();
      final double rightEyeX = face.landmarks[FaceLandmarkType.rightEye]!.position.x.toDouble();
      final double rightEyeY = face.landmarks[FaceLandmarkType.rightEye]!.position.y.toDouble();

      final double dx = leftEyeX - rightEyeX;
      final double dy = leftEyeY - rightEyeY;
      final double pixelIpd = sqrt(dx * dx + dy * dy);
      _pixelIpd = pixelIpd;
      _faceBoundingBox = face.boundingBox;

      if (_testStatus == TestStatus.calibration) {
        _calibrationPixelIpds.add(pixelIpd);
        if (_calibrationPixelIpds.length > 20) _calibrationPixelIpds.removeAt(0);
        
        // Instant visual feedback for user
        final tempDist = (_focalLength * realIpdMm) / pixelIpd;
        _currentDistanceCm = tempDist / 10.0;
      } else {
        final rawDistMm = (_focalLength * realIpdMm) / pixelIpd;
        final rawDistCm = rawDistMm / 10.0;
        
        // Moving average smoothing
        _distanceHistory.add(rawDistCm);
        if (_distanceHistory.length > _historySize) _distanceHistory.removeAt(0);
        _currentDistanceCm = _distanceHistory.reduce((a, b) => a + b) / _distanceHistory.length;
      }
      notifyListeners();
    } else {
        _faceBoundingBox = null;
        notifyListeners();
    }
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
    _distanceHistory.clear();
    notifyListeners();
  }

  void submitRowResult(int errors) {
    if (_lastRowShownTime != null) {
      _responseTimes.add(DateTime.now().difference(_lastRowShownTime!).inMilliseconds.toDouble() / 1000.0);
    }
    
    _missedChars += errors;
    int charsInRow = currentRow.letters.replaceAll(' ', '').length;
    
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
  }) async {
    _isProcessingAI = true;
    notifyListeners();

    try {
      final snellenData = {
        'smallest_row_read': _smallestRowRead,
        'missed_chars': _missedChars,
        'avg_distance_cm': _currentDistanceCm,
        'response_times': _responseTimes,
      };

      final result = await _apiService.postAIRefractionAI(
        imageBase64: imageBase64,
        snellenData: snellenData,
        deviceInfo: deviceInfo,
      );

      if (result['success']) {
        final data = result['data'];
        _aiResultCategory = data['kategori'] ?? 'Unknown';
        
        if (data['confidence'] is String) {
           _aiConfidence = double.tryParse(data['confidence'].replaceAll('%', '')) ?? 0.0;
        } else if (data['confidence'] is num) {
           _aiConfidence = (data['confidence'] as num).toDouble();
           if (_aiConfidence! < 1.0) _aiConfidence = _aiConfidence! * 100;
        } else {
           _aiConfidence = 0.0;
        }
      } else {
         _aiResultCategory = "Error: ${result['message']}";
      }
    } catch (e) {
      _aiResultCategory = "Error: $e";
    } finally {
      _isProcessingAI = false;
      notifyListeners();
    }
  }

  void resetTest() {
    _testStatus = TestStatus.calibration;
    _isCalibrated = false;
    _focalLength = 500; 
    _currentDistanceCm = 0;
    _currentRowIndex = 0;
    _missedChars = 0;
    _smallestRowRead = 200;
    _aiResultCategory = null;
    _aiConfidence = null;
    _distanceHistory.clear();
    _calibrationPixelIpds.clear();
    notifyListeners();
  }
}
