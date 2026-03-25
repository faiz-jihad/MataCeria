import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class CameraProcessor {
  // Convert YUV420 to RGB Image (runs in isolate)
  static Future<String?> processEyeRegionBase64({
    required CameraImage cameraImage,
    required Face face,
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
  }) async {
    // Collect Face data before passing to isolate
    final bbox = {
      'left': face.boundingBox.left.toInt(),
      'top': face.boundingBox.top.toInt(),
      'right': face.boundingBox.right.toInt(),
      'bottom': face.boundingBox.bottom.toInt(),
    };

    // Need to pass raw plane bytes
    final List<Map<String, dynamic>> planesInfo = [];
    final List<Uint8List> planesBytes = [];
    
    for (var plane in cameraImage.planes) {
      planesInfo.add({
        'bytesPerRow': plane.bytesPerRow,
        'bytesPerPixel': plane.bytesPerPixel,
      });
      planesBytes.add(plane.bytes);
    }
    
    final Map<String, dynamic> isolateData = {
      'width': cameraImage.width,
      'height': cameraImage.height,
      'planesInfo': planesInfo,
      'planesBytes': planesBytes,
      'faceBbox': bbox,
      'sensorOrientation': sensorOrientation,
      'lensDirection': lensDirection.index,
    };

    return await Isolate.run(() => _processInIsolate(isolateData));
  }

  static String? _processInIsolate(Map<String, dynamic> data) {
    try {
      final int width = data['width'];
      final int height = data['height'];
      final List<Map<String, dynamic>> planesInfo = data['planesInfo'];
      final List<Uint8List> planesBytes = data['planesBytes'];

      // 1. Convert YUV to RGB using `image` package
      img.Image image = _convertYUV420ToImage(
        width: width,
        height: height,
        plane0: planesBytes[0],
        plane1: planesBytes[1],
        plane2: planesBytes[2],
        bytesPerRow0: planesInfo[0]['bytesPerRow'],
        bytesPerRow1: planesInfo[1]['bytesPerRow'],
        bytesPerPixel1: planesInfo[1]['bytesPerPixel'],
      );

      // 2. Rotate image based on sensor orientation
      final int rotationAngle = data['sensorOrientation'];
      if (rotationAngle != 0) {
         image = img.copyRotate(image, angle: rotationAngle);
      }
      
      // If Front camera, image might need to be flipped horizontally depending on rendering, 
      // but usually for ML we just need the crop of the face.

      // 3. Crop to face region (with some padding for eyes)
      // Note: Bounding boxes from ML Kit are relative to the *rotated* image size
      final bbox = data['faceBbox'];
      int cropX = bbox['left'];
      int cropY = bbox['top'];
      int cropWidth = bbox['right'] - bbox['left'];
      int cropHeight = bbox['bottom'] - bbox['top'];

      // Focus more on upper half of face (eyes)
      int eyeRegionHeight = (cropHeight * 0.6).toInt();
      
      // Ensure bounds
      cropX = cropX.clamp(0, image.width - 1);
      cropY = cropY.clamp(0, image.height - 1);
      cropWidth = cropWidth.clamp(1, image.width - cropX);
      eyeRegionHeight = eyeRegionHeight.clamp(1, image.height - cropY);

      img.Image cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: eyeRegionHeight,
      );

      // 4. Resize to 224x224 (Standard for many CNNs)
      img.Image resized = img.copyResize(cropped, width: 224, height: 224);

      // 5. Encode to JPEG
      final List<int> jpegBytes = img.encodeJpg(resized, quality: 80);

      // 6. Convert to Base64
      return base64Encode(jpegBytes);
    } catch (e) {
      print("Isolate processing error: \$e");
      return null;
    }
  }

  // Helper YUV420 to RGB (Dart adaptation)
  static img.Image _convertYUV420ToImage({
    required int width,
    required int height,
    required Uint8List plane0,
    required Uint8List plane1,
    required Uint8List plane2,
    required int bytesPerRow0,
    required int bytesPerRow1,
    required int? bytesPerPixel1,
  }) {
    final img.Image image = img.Image(width: width, height: height);

    final int uvRowStride = bytesPerRow1;
    final int? uvPixelStride = bytesPerPixel1;

    for (int y = 0; y < height; y++) {
      int uvRow = y >> 1;
      for (int x = 0; x < width; x++) {
        int uvCol = x >> 1;
        int indexY = y * bytesPerRow0 + x;
        int indexUV = uvRow * uvRowStride + uvCol * (uvPixelStride ?? 2);

        // Calculate Y, U, V
        int yValue = plane0[indexY];
        int uValue = plane1[indexUV];
        int vValue = plane2[indexUV];

        // Convert YUV to RGB
        int r = (yValue + 1.402 * (vValue - 128)).toInt();
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).toInt();
        int b = (yValue + 1.772 * (uValue - 128)).toInt();

        // Clamp
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }
}
