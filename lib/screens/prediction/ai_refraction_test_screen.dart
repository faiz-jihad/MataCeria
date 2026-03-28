import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/refraction_test_provider.dart';
import '../../l10n/app_strings.dart';
import '../../utils/camera_processor.dart';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class AIRefractionTestScreen extends StatefulWidget {
  const AIRefractionTestScreen({super.key});

  @override
  State<AIRefractionTestScreen> createState() => _AIRefractionTestScreenState();
}

class _AIRefractionTestScreenState extends State<AIRefractionTestScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  DateTime? _lastDetectionTime;
  bool _cameraInitialized = false;
  bool _faceFound = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDisclaimer();
    });
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      
      // Fallback for older camera plugin versions that might not support nv21
      if (Platform.isAndroid && _cameraController!.imageFormatGroup == ImageFormatGroup.unknown) {
         _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.yuv420,
         );
      }

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraInitialized = true);

      unawaited(_cameraController!.startImageStream((image) {
        if (_isDetecting) return;
        _isDetecting = true;
        _processCameraImage(image);
      }));
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final provider = Provider.of<RefractionTestProvider>(context, listen: false);
      final now = DateTime.now();
      
      if (_lastDetectionTime != null && 
          now.difference(_lastDetectionTime!).inMilliseconds < 500) {
        _isDetecting = false;
        return;
      }
      _lastDetectionTime = now;

      // Initialize FaceDetector if needed
      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      final inputImage = CameraProcessor.getInputImageFromCameraImage(
        cameraImage: image,
        sensorOrientation: _cameraController!.description.sensorOrientation,
      );

      final faces = await _faceDetector!.processImage(inputImage);
      
      if (mounted) {
        setState(() => _faceFound = faces.isNotEmpty);
      }
      
      if (faces.isEmpty) {
        if (mounted && provider.testStatus != TestStatus.finished) {
           provider.updateDistanceLocally(0.0, 0.0);
        }
        _isDetecting = false;
        return;
      }

      final targetFace = faces.first;

      // 1. Update Distance
      final fullBase64 = await CameraProcessor.convertFullImageToBase64(
        cameraImage: image,
        sensorOrientation: _cameraController!.description.sensorOrientation,
      );
      
      if (fullBase64 != null && mounted) {
        await provider.updateDistanceRemote(fullBase64);
        
        // 2. Process AI Result if finished
        if (provider.testStatus == TestStatus.finished && !provider.isProcessingAI && provider.aiResultCategory == null) {
          unawaited(_cameraController?.stopImageStream());
          
          debugPrint('REFRACTION_DEBUG: Test finished. Processing eye crop...');

          final eyeCropBase64 = await CameraProcessor.processEyeRegionBase64(
            cameraImage: image,
            face: targetFace,
            sensorOrientation: _cameraController!.description.sensorOrientation,
            lensDirection: _cameraController!.description.lensDirection,
          );

          if (eyeCropBase64 != null && mounted) {
            final screenPpi = MediaQuery.of(context).devicePixelRatio * 160;
            await provider.processAIResult(
               imageBase64: eyeCropBase64,
               deviceInfo: Platform.operatingSystem,
               screenPpi: screenPpi,
            );
            
            if (mounted) {
              unawaited(Provider.of<AuthProvider>(context, listen: false).reloadUser());
            }
          } else {
             debugPrint('REFRACTION_DEBUG: Failed to generate eye crop.');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in camera processing loop: $e');
    } finally {
      if (mounted) _isDetecting = false;
    }
  }


  void _showDisclaimer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Medical Disclaimer')
          ],
        ),
        content: Text("${"camera_disclaimer".tr(context)}\n\nAplikasi ini hanya untuk skrining awal dan bukan pengganti diagnosis medis profesional."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Saya Mengerti'),
          )
        ],
      ),
    );
  }

  IconData _getConditionIcon(String result) {
    final r = result.toLowerCase();
    if (r.contains('normal')) return Icons.check_circle_outline;
    if (r.contains('mild')) return Icons.visibility_outlined;
    if (r.contains('myopia') || r.contains('miopi')) return Icons.remove_red_eye;
    if (r.contains('severe')) return Icons.warning_rounded;
    if (r.contains('hiper')) return Icons.visibility;
    if (r.contains('astig')) return Icons.blur_on;
    return Icons.psychology;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Snellen Test'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<RefractionTestProvider>(
        builder: (context, provider, child) {
          final distance = provider.currentDistanceCm;
          Color statusColor = Colors.grey;
          var statusText = 'camera_detecting'.tr(context);

          if (distance > 0) {
            if (distance < 30) {
              statusColor = Colors.red;
              statusText = 'camera_too_close'.tr(context);
            } else if (distance >= 30 && distance <= 55) {
              statusColor = Colors.green;
              statusText = 'camera_ideal'.tr(context);
            } else if (distance > 55) {
              statusColor = Colors.orange;
              statusText = 'camera_too_far'.tr(context);
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: statusColor.withValues(alpha: 0.9),
                child: Column(
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Posisikan mata tepat di dalam kotak & jarak 30-40 cm.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (distance > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${distance.toStringAsFixed(1)} cm',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Face feedback
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _faceFound ? Icons.face : Icons.face_retouching_off,
                          color: _faceFound ? Colors.white : Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _faceFound ? 'Mata Terdeteksi' : 'Posisikan Mata',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Camera Preview dengan Countdown Overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 120,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                  if (provider.countdown > 0)
                    Container(
                      height: 150,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${provider.countdown}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildTestContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildTestContent(RefractionTestProvider provider) {
    if (provider.testStatus == TestStatus.calibration) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.center_focus_strong, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'calibration_title'.tr(context),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'calibration_desc'.tr(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (provider.currentDistanceCm >= 35 && provider.currentDistanceCm <= 45 && provider.countdown == 0)
                ? () {
                    provider.startCountdown(() {
                      provider.finishCalibration();
                    });
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(provider.countdown > 0 ? '...' : 'calibration_btn'.tr(context)),
            )
          ],
        ),
      );
    } else if (provider.testStatus == TestStatus.ready) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            provider.startTest();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: Text('start_test_btn'.tr(context)),
        ),
      );
    } else if (provider.testStatus == TestStatus.testing) {
      final row = provider.currentRow;
      
      final distanceMm = provider.currentDistanceCm > 0 ? provider.currentDistanceCm * 10.0 : 400.0;
      final heightMm = distanceMm * 0.0014544 * (row.distanceRef / 20.0);
      
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final logicalPx = (heightMm / 25.4) * (160 * pixelRatio) / pixelRatio; 

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${'test_row'.tr(context)} ${provider.currentRowIndex + 1} (20/${row.distanceRef})",
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              row.letters,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: logicalPx,
                fontWeight: FontWeight.bold,
                letterSpacing: logicalPx * 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('test_question'.tr(context)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInputBtn(provider, 0, 'test_all_correct'.tr(context), Colors.green),
                    _buildInputBtn(provider, 1, 'test_1_wrong'.tr(context), Colors.orange),
                    _buildInputBtn(provider, 2, 'test_2_wrong'.tr(context), Colors.red),
                  ],
                ),
              ],
            ),
          )
        ],
      );
    } else {
      // testStatus == TestStatus.finished
      if (provider.isProcessingAI || provider.aiResultCategory == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('ai_analyzing'.tr(context)),
            ],
          ),
        );
      }

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getConditionIcon(provider.aiResultCategory ?? ''),
                size: 80,
                color: (provider.aiActionRequired) ? Colors.red : Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.aiActionRequired)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    ),
                  const Text(
                    'AI Refraction Result',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: provider.aiActionRequired ? Colors.red.shade300 : Colors.deepPurple.shade200,
                    width: provider.aiActionRequired ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      provider.aiResultCategory ?? 'Unknown',
                      style: TextStyle(
                         fontSize: 28, 
                         fontWeight: FontWeight.bold,
                         color: (provider.aiActionRequired || (provider.aiResultCategory?.toLowerCase().contains('error') ?? false))
                             ? Colors.red 
                             : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (provider.aiVisualAcuity != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Visual Acuity: ${provider.aiVisualAcuity}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResultStat('Snellen Score', '20/${provider.smallestRowRead}'),
                        if (provider.aiSnellenDecimal != null)
                          _buildResultStat('Decimal', provider.aiSnellenDecimal!.toStringAsFixed(2)),
                        _buildResultStat('Avg Distance', '${provider.currentDistanceCm.toStringAsFixed(1)} cm'),
                      ],
                    ),
                    if (provider.aiConfidence != null) ...[
                      const SizedBox(height: 4),
                       Text(
                        'Confidence: ${provider.aiConfidence!.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                       )
                    ],
                    if (provider.aiRecommendation != null && provider.aiRecommendation!.isNotEmpty) ...[
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: provider.aiActionRequired ? Colors.red.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          provider.aiRecommendation!,
                          style: TextStyle(
                            fontSize: 15, 
                            color: provider.aiActionRequired ? Colors.red.shade800 : Colors.black87, 
                            fontStyle: FontStyle.italic,
                            fontWeight: provider.aiActionRequired ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (provider.aiCanConsultChatbot) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    // Reset test state before navigating away
                    provider.resetTest();
                    Navigator.pushReplacementNamed(context, '/chat');
                  },
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('Tanya Chatbot MataCeria'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: () {
                  provider.resetTest();
                  Navigator.pop(context);
                },
                child: Text('test_back'.tr(context)),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInputBtn(RefractionTestProvider provider, int errors, String label, Color color) {
    final isIdeal = provider.currentDistanceCm >= 30 && provider.currentDistanceCm <= 55;
    return ElevatedButton(
      onPressed: !provider.isCalibrated ? null : () {
        provider.submitRowResult(errors);
        // Refresh profile stats if test finished
        if (provider.testStatus == TestStatus.finished && mounted) {
           Provider.of<AuthProvider>(context, listen: false).reloadUser();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isIdeal ? color : color.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
  Widget _buildResultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

}
