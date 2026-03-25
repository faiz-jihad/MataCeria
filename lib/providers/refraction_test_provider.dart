import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';

enum TestStatus { calibration, ready, testing, finished }

class SnellenRow {
  final int distanceRef; // Denominator of fraction (e.g. 200, 100, etc)
  final String letters;

  SnellenRow({required this.distanceRef, required this.letters});
}

class RefractionTestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  TestStatus _testStatus = TestStatus.calibration;
  TestStatus get testStatus => _testStatus;

  double _focalLength = 0;
  bool _isCalibrated = false;
  bool get isCalibrated => _isCalibrated;

  double _currentDistanceCm = 0;
  double get currentDistanceCm => _currentDistanceCm;

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

  int _smallestRowRead = 200; // default worst score
  int get smallestRowRead => _smallestRowRead;

  // For distance logic
  final double realIpdMm = 63.0; // Average human Inter-Pupillary Distance

  void updateDistance(Face face) {
    if (face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null) {
      final double leftEyeX = face.landmarks[FaceLandmarkType.leftEye]!.position.x.toDouble();
      final double leftEyeY = face.landmarks[FaceLandmarkType.leftEye]!.position.y.toDouble();
      final double rightEyeX = face.landmarks[FaceLandmarkType.rightEye]!.position.x.toDouble();
      final double rightEyeY = face.landmarks[FaceLandmarkType.rightEye]!.position.y.toDouble();

      // Calculate distance between eyes in pixels
      final double dx = leftEyeX - rightEyeX;
      final double dy = leftEyeY - rightEyeY;
      final double pixelIpd = sqrt(dx * dx + dy * dy);
      _pixelIpd = pixelIpd;
      _faceBoundingBox = face.boundingBox;

      if (_testStatus == TestStatus.calibration) {
        // Assume user holds phone at exactly 40cm during calibration
        // Focal Length = (Distance * Pixel IPD) / Real IPD
        // 40cm = 400mm
        _focalLength = (400.0 * pixelIpd) / realIpdMm;
      } else if (_isCalibrated && pixelIpd > 0) {
        // Distance (mm) = (Focal Length * Real IPD) / Pixel IPD
        final distMm = (_focalLength * realIpdMm) / pixelIpd;
        _currentDistanceCm = distMm / 10.0;
        notifyListeners();
      }
    } else {
        _faceBoundingBox = null;
        notifyListeners();
    }
  }

  void finishCalibration() {
    _isCalibrated = true;
    _testStatus = TestStatus.ready;
    notifyListeners();
  }

  void startTest() {
    _testStatus = TestStatus.testing;
    _currentRowIndex = 0;
    _missedChars = 0;
    _smallestRowRead = 200;
    _responseTimes.clear();
    _lastRowShownTime = DateTime.now();
    notifyListeners();
  }

  void submitRowResult(int errors) {
    if (_lastRowShownTime != null) {
      _responseTimes.add(DateTime.now().difference(_lastRowShownTime!).inMilliseconds.toDouble() / 1000.0);
    }
    
    _missedChars += errors;
    
    // Logic to determine if they pass the row.
    // E.g., if total errors in this row > half the letters, they fail.
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
        
        // Handle variations in API response (string '95%' or double 0.95)
        if (data['confidence'] is String) {
           _aiConfidence = double.tryParse(data['confidence'].replaceAll('%', '')) ?? 0.0;
        } else if (data['confidence'] is num) {
           _aiConfidence = (data['confidence'] as num).toDouble();
           // if it's less than 1, it might be a probability. Convert to percentage if needed.
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
    _focalLength = 0;
    _currentDistanceCm = 0;
    _currentRowIndex = 0;
    _missedChars = 0;
    _smallestRowRead = 200;
    _aiResultCategory = null;
    _aiConfidence = null;
    notifyListeners();
  }
}
