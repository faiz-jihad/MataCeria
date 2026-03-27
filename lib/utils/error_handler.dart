import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void handleError(dynamic error, BuildContext context) {
    debugPrint('Error caught: $error');
    final message = _getErrorMessage(error);
    showErrorSnackBar(context, message);
  }

  static String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Koneksi terputus. Silakan coba lagi.';
        case DioExceptionType.sendTimeout:
          return 'Gagal mengirim data. Periksa koneksi Anda.';
        case DioExceptionType.receiveTimeout:
          return 'Server lambat merespon. Silakan coba lagi.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) return 'Sesi berakhir. Silakan login kembali.';
          if (statusCode == 403) return 'Anda tidak memiliki akses.';
          if (statusCode == 404) return 'Layanan tidak ditemukan.';
          if (statusCode == 500) return 'Terjadi kesalahan pada server.';
          return 'Kesalahan server: $statusCode';
        case DioExceptionType.cancel:
          return 'Permintaan dibatalkan.';
        case DioExceptionType.connectionError:
          return 'Tidak ada koneksi internet.';
        default:
          return 'Terjadi kesalahan jaringan.';
      }
    }
    return 'Terjadi kesalahan: ${error.toString()}';
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
