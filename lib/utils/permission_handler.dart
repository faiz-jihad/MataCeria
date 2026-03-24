// lib/utils/permission_handler.dart

import 'package:permission_handler/permission_handler.dart';


class PermissionHandler {
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    
    if (status.isDenied) {
      // Minta izin
      status = await Permission.camera.request();
    }
    
    if (status.isPermanentlyDenied) {
      // User pernah menolak permanen, arahkan ke settings
      await openAppSettings();
      return false;
    }
    
    return status.isGranted;
  }
  
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isDenied) {
      return await Permission.storage.request().isGranted;
    }
    return true;
  }
}