import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/refraction_test_provider.dart';
import '../../l10n/app_strings.dart';
import '../../utils/camera_processor.dart';

class RefractionTestScreen extends StatefulWidget {
  const RefractionTestScreen({super.key});

  @override
  State<RefractionTestScreen> createState() => _RefractionTestScreenState();
}

class _RefractionTestScreenState extends State<RefractionTestScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  DateTime? _lastDetectionTime;
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
        ResolutionPreset.medium, // Better for landmark precision
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraInitialized = true);

      _cameraController!.startImageStream((image) {
        if (_isDetecting) return;
        _isDetecting = true;
        _processCameraImage(image);
      });
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // Throttle backend calls (e.g., every 400ms)
      final now = DateTime.now();
      if (_lastDetectionTime != null && 
          now.difference(_lastDetectionTime!).inMilliseconds < 400) {
        return;
      }
      _lastDetectionTime = now;

      final provider = Provider.of<RefractionTestProvider>(context, listen: false);
      
      // Convert frame to Base64 for backend (using CameraProcessor for valid JPEG)
      final base64Image = await CameraProcessor.convertFullImageToBase64(
        cameraImage: image,
        sensorOrientation: _cameraController!.description.sensorOrientation,
      );
      
      if (base64Image != null && mounted) {
        await provider.updateDistanceRemote(base64Image);
      }
    } catch (e) {
      debugPrint('Error detecting face via backend: $e');
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
        content: Text('camera_disclaimer'.tr(context)),
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

  @override
  void dispose() {
    _cameraController?.dispose();
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
        title: Text('test_eye_title'.tr(context)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<RefractionTestProvider>(
        builder: (context, provider, child) {
          final distance = provider.currentDistanceCm;
          Color statusColor = Colors.grey;
          var statusText = 'camera_detecting'.tr(context);

          if (provider.isCalibrated) {
            if (distance < 30) {
              statusColor = Colors.red;
              statusText = 'camera_too_close'.tr(context);
            } else if (distance >= 30 && distance <= 50) {
              statusColor = Colors.green;
              statusText = 'camera_ideal'.tr(context);
            } else if (distance > 50) {
              statusColor = Colors.orange;
              statusText = 'camera_too_far'.tr(context);
            }
          }

          return Column(
            children: [
              // Feedback Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: statusColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isDetectingRemote && !provider.isCalibrated) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (provider.isCalibrated && distance > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${distance.toStringAsFixed(1)} cm',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Camera Preview
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
                        color: Colors.black.withOpacity(0.4),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text('test_done'.tr(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("${'test_score'.tr(context)} 20/${provider.smallestRowRead}", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.resetTest();
                Navigator.pop(context);
              },
              child: Text('test_back'.tr(context)),
            )
          ],
        ),
      );
    }
  }

  Widget _buildInputBtn(RefractionTestProvider provider, int errors, String label, Color color) {
    // Relaxation: Allow input even if slightly out of range, but highlight current distance
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
        backgroundColor: isIdeal ? color : color.withOpacity(0.5),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
