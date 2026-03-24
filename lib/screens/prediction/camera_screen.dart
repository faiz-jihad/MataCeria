// lib/screens/prediction/camera_screen.dart

import 'dart:io' as io show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/eye_refraction_provider.dart';
import '../../utils/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? _imageFile;
  bool _isServiceChecking = true;

  @override
  void initState() {
    super.initState();
    _checkServiceHealth();
  }

  Future<void> _checkServiceHealth() async {
    setState(() => _isServiceChecking = true);
    final provider = Provider.of<EyeRefractionProvider>(context, listen: false);
    await provider.checkMLHealth();
    setState(() => _isServiceChecking = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request izin kamera
    bool hasPermission = await PermissionHandler.requestCameraPermission();
    if (!hasPermission) {
      _showErrorSnackBar('Izin kamera diperlukan');
      return;
    }
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      } else {
        _showErrorSnackBar('Tidak ada gambar yang dipilih');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      _showErrorSnackBar('Pilih gambar terlebih dahulu');
      return;
    }
    
    final provider = Provider.of<EyeRefractionProvider>(context, listen: false);
    
    // Cek service health sebelum analisis
    if (!provider.serviceHealthy) {
      final isHealthy = await provider.checkMLHealth();
      if (!isHealthy) {
        _showErrorSnackBar('ML Service tidak tersedia. Jalankan python app.py');
        return;
      }
    }
    
    final success = await provider.detectEyeRefraction(_imageFile!);
    
    if (success && mounted) {
      Navigator.pushNamed(context, '/result');
    } else {
      _showErrorSnackBar(provider.errorMessage ?? 'Gagal mendeteksi');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EyeRefractionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Refraksi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildServiceStatus(provider),
        ],
      ),
      body: _isServiceChecking
          ? const Center(child: CircularProgressIndicator())
          : provider.isLoading
              ? _buildLoadingState()
              : _imageFile == null
                  ? _buildPickImage(provider)
                  : _buildPreviewImage(),
    );
  }

  Widget _buildServiceStatus(EyeRefractionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: provider.serviceHealthy ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.serviceHealthy ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            provider.serviceHealthy ? 'ML Ready' : 'ML Offline',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Menganalisis gambar...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPickImage(EyeRefractionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate,
              size: 80,
              color: Colors.blue.shade400,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          const Text(
            'Deteksi Refraksi Mata',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Subtitle
          const Text(
            'Ambil foto atau pilih dari galeri untuk mendeteksi kondisi refraksi mata',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Warning jika ML Service offline
          if (!provider.serviceHealthy) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ML Service Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jalankan python app.py di terminal',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Tombol Pilih Gambar
          Row(
            children: [
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  color: Colors.blue,
                  onPressed: provider.serviceHealthy 
                      ? () => _pickImage(ImageSource.camera)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  color: Colors.green,
                  onPressed: provider.serviceHealthy 
                      ? () => _pickImage(ImageSource.gallery)
                      : null,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Tombol refresh untuk cek ulang service
          TextButton.icon(
            onPressed: _checkServiceHealth,
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Ulang Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed != null ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildPreviewImage() {
    return Column(
      children: [
        // Image Preview
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar
               kIsWeb 
                ? Image.network(
                    _imageFile!.path,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    io.File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Info overlay
              Positioned(
                bottom: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Siap Dianalisis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Ulangi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analyzeImage,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analisis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info kecil
              const Text(
                'Pastikan gambar wajah jelas dan pencahayaan cukup',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}