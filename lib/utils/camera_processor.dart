import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class CameraProcessor {
  // Convert CameraImage to InputImage for ML Kit
  static InputImage getInputImageFromCameraImage({
    required CameraImage cameraImage,
    required int sensorOrientation,
  }) {
    final allBytes = WriteBuffer();
    for (final plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) 
        ?? InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw) 
        ?? InputImageFormat.yuv420;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      ),
    );
  }

  // Convert full YUV420 to JPEG Base64 (runs in isolate)
  static Future<String?> convertFullImageToBase64({
    required CameraImage cameraImage,
    required int sensorOrientation,
  }) async {
    // Need to pass raw plane bytes
    final planesInfo = <Map<String, dynamic>>[];
    final planesBytes = <Uint8List>[];
    
    for (var plane in cameraImage.planes) {
      planesInfo.add({
        'bytesPerRow': plane.bytesPerRow,
        'bytesPerPixel': plane.bytesPerPixel,
      });
      planesBytes.add(plane.bytes);
    }
    
    final isolateData = <String, dynamic>{
      'width': cameraImage.width,
      'height': cameraImage.height,
      'planesInfo': planesInfo,
      'planesBytes': planesBytes,
      'sensorOrientation': sensorOrientation,
      'isFullImage': true,
    };

    return await Isolate.run(() => _processInIsolate(isolateData));
  }

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
    final planesInfo = <Map<String, dynamic>>[];
    final planesBytes = <Uint8List>[];
    
    for (var plane in cameraImage.planes) {
      planesInfo.add({
        'bytesPerRow': plane.bytesPerRow,
        'bytesPerPixel': plane.bytesPerPixel,
      });
      planesBytes.add(plane.bytes);
    }
    
    final isolateData = <String, dynamic>{
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
      var image = _convertYUV420ToImage(
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
      
      if (data['isFullImage'] == true) {
        // Just resize a bit to save bandwidth if full image
        final resized = img.copyResize(image, width: 480); // 480px width is enough for face detection
        final List<int> jpegBytes = img.encodeJpg(resized, quality: 70);
        return base64Encode(jpegBytes);
      }

      // 3. Crop to face region (with some padding for eyes)
      // Note: Bounding boxes from ML Kit are relative to the *rotated* image size
      final bbox = data['faceBbox'];
      int cropX = bbox['left'];
      int cropY = bbox['top'];
      int cropWidth = bbox['right'] - bbox['left'];
      final int cropHeight = bbox['bottom'] - bbox['top'];

      // Focus more on upper half of face (eyes)
      var eyeRegionHeight = (cropHeight * 0.6).toInt();
      
      // Ensure bounds
      cropX = cropX.clamp(0, image.width - 1);
      cropY = cropY.clamp(0, image.height - 1);
      cropWidth = cropWidth.clamp(1, image.width - cropX);
      eyeRegionHeight = eyeRegionHeight.clamp(1, image.height - cropY);

      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: eyeRegionHeight,
      );

      // 4. Resize to 224x224 (Standard for many CNNs)
      final resized = img.copyResize(cropped, width: 224, height: 224);

      // 5. Encode to JPEG
      final List<int> jpegBytes = img.encodeJpg(resized, quality: 80);

      // 6. Convert to Base64
      return base64Encode(jpegBytes);
    } catch (e) {
      debugPrint('Isolate processing error: $e');
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
    final image = img.Image(width: width, height: height);

    final uvRowStride = bytesPerRow1;
    final uvPixelStride = bytesPerPixel1;

    for (var y = 0; y < height; y++) {
      final uvRow = y >> 1;
      for (var x = 0; x < width; x++) {
        final uvCol = x >> 1;
        final indexY = y * bytesPerRow0 + x;
        final indexUV = uvRow * uvRowStride + uvCol * (uvPixelStride ?? 2);

        // Calculate Y, U, V
        final yValue = plane0[indexY];
        final uValue = plane1[indexUV];
        final vValue = plane2[indexUV];

        // Convert YUV to RGB
        var r = (yValue + 1.402 * (vValue - 128)).toInt();
        var g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).toInt();
        var b = (yValue + 1.772 * (uValue - 128)).toInt();

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
