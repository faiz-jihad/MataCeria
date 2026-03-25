import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../providers/refraction_test_provider.dart';
import '../../utils/camera_processor.dart';
import '../../l10n/app_strings.dart';

class AIRefractionTestScreen extends StatefulWidget {
  const AIRefractionTestScreen({super.key});

  @override
  State<AIRefractionTestScreen> createState() => _AIRefractionTestScreenState();
}

class _AIRefractionTestScreenState extends State<AIRefractionTestScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableClassification: false,
    ),
  );
  bool _isDetecting = false;
  bool _cameraInitialized = false;

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
        ResolutionPreset.medium, // Using medium for better eye crops
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraInitialized = true);

      _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;
        _processCameraImage(image);
      });
    } catch (e) {
      debugPrint("Camera Error: \$e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final provider = Provider.of<RefractionTestProvider>(context, listen: false);

      // 1. Detect Face for Distance
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotation.rotation270deg; 
      final InputImageFormat inputImageFormat = InputImageFormat.yuv420;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isNotEmpty && mounted) {
        final face = faces.first;
        provider.updateDistance(face);
        
        // 2. If test is finishing, trigger AI Processing
        if (provider.testStatus == TestStatus.finished && !provider.isProcessingAI && provider.aiResultCategory == null) {
          _cameraController?.stopImageStream();
          final String deviceInfo = Platform.operatingSystem;
          
          final base64Image = await CameraProcessor.processEyeRegionBase64(
             cameraImage: image,
             face: face,
             sensorOrientation: _cameraController!.description.sensorOrientation,
             lensDirection: _cameraController!.description.lensDirection,
          );

          if (base64Image != null && mounted) {
             await provider.processAIResult(
                imageBase64: base64Image,
                deviceInfo: deviceInfo,
             );
          }
        }
      }
    } catch (e) {
      debugPrint("Error detecting face: \$e");
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
            Text("Medical Disclaimer")
          ],
        ),
        content: Text("camera_disclaimer".tr(context) + "\n\nAplikasi ini hanya untuk skrining awal dan bukan pengganti diagnosis medis profesional."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Saya Mengerti"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
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
          String statusText = "camera_detecting".tr(context);

          if (provider.isCalibrated) {
            if (distance < 30) {
              statusColor = Colors.red;
              statusText = "camera_too_close".tr(context);
            } else if (distance >= 30 && distance <= 50) {
              statusColor = Colors.green;
              statusText = "camera_ideal".tr(context);
            } else if (distance > 50) {
              statusColor = Colors.orange;
              statusText = "camera_too_far".tr(context);
            }
          }

          return Column(
            children: [
              // Feedback Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: statusColor,
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              // Camera Preview
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
              const SizedBox(height: 16),
              // Main Test Area
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
              "calibration_title".tr(context),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "calibration_desc".tr(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.finishCalibration();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text("calibration_btn".tr(context)),
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
          child: Text("start_test_btn".tr(context)),
        ),
      );
    } else if (provider.testStatus == TestStatus.testing) {
      final row = provider.currentRow;
      
      double distanceMm = provider.currentDistanceCm > 0 ? provider.currentDistanceCm * 10.0 : 400.0;
      double heightMm = distanceMm * 0.0014544 * (row.distanceRef / 20.0);
      
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      double logicalPx = (heightMm / 25.4) * (160 * pixelRatio) / pixelRatio; 

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
                Text("test_question".tr(context)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInputBtn(provider, 0, "test_all_correct".tr(context), Colors.green),
                    _buildInputBtn(provider, 1, "test_1_wrong".tr(context), Colors.orange),
                    _buildInputBtn(provider, 2, "test_2_wrong".tr(context), Colors.red),
                  ],
                ),
              ],
            ),
          )
        ],
      );
    } else {
      // Test is finished - show processing or results
      if (provider.isProcessingAI) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Menganalisis hasil refraksi menggunakan AI..."),
            ],
          ),
        );
      }

      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text(
                  "AI Refraction Result",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${provider.aiResultCategory}",
                        style: TextStyle(
                           fontSize: 28, 
                           fontWeight: FontWeight.bold,
                           color: provider.aiResultCategory!.toLowerCase().contains('error') 
                               ? Colors.red 
                               : Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (provider.aiConfidence != null) ...[
                        const SizedBox(height: 8),
                         Text(
                          "Confidence: ${provider.aiConfidence!.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Snellen Score: 20/${provider.smallestRowRead}", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)
                ),
                Text(
                  "Avg Distance: ${provider.currentDistanceCm.toStringAsFixed(1)} cm", 
                  style: const TextStyle(fontSize: 16, color: Colors.grey)
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    provider.resetTest();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.deepPurple,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text("test_back".tr(context)),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInputBtn(RefractionTestProvider provider, int errors, String label, Color color) {
    return ElevatedButton(
      onPressed: provider.currentDistanceCm < 30 || provider.currentDistanceCm > 50 
        ? null // Disable if not in ideal range
        : () {
        provider.submitRowResult(errors);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
