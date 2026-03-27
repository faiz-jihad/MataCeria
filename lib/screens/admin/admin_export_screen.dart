import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';

class AdminExportScreen extends StatefulWidget {
  const AdminExportScreen({super.key});

  @override
  State<AdminExportScreen> createState() => _AdminExportScreenState();
}

class _AdminExportScreenState extends State<AdminExportScreen> {
  final ApiService _apiService = ApiService();
  bool _isExporting = false;
  String _status = 'Siap mengekspor data user...';

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _status = 'Mengambil data dari server...';
    });

    try {
      final users = await _apiService.getAdminUsers();
      
      if (users.isEmpty) {
        setState(() {
          _isExporting = false;
          _status = 'Tidak ada data user untuk diekspor.';
        });
        return;
      }

      setState(() => _status = 'Menyusun format CSV...');

      // Generate CSV content
      var csvContent = 'ID,Nama,Email,Umur,Kelamin,Role,Visi,Tanggal Daftar\n';
      for (var user in users) {
        csvContent += '${user['id']??""},';
        csvContent += '"${user['nama_lengkap'] ?? user['name'] ?? ""}",';
        csvContent += '"${user['email'] ?? ""}",';
        csvContent += '${user['umur'] ?? ""},';
        csvContent += '"${user['kelamin'] ?? ""}",';
        csvContent += '"${user['role'] ?? ""}",';
        csvContent += '"${user['vision_type'] ?? ""}",';
        csvContent += '"${user['created_at'] ?? ""}"\n';
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/data_user_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);

      setState(() => _status = 'Berhasil! Membuka menu bagi...');

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Export Data User MataCeria');

      setState(() {
        _isExporting = false;
        _status = 'Ekspor selesai.';
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _status = 'Gagal: $e';
      });
      _showErrorSnackBar('Terjadi kesalahan saat ekspor');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ekspor Data', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_rounded, size: 80, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 30),
            const Text(
              'Ekspor Semua Data User',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Gunakan fitur ini untuk mengunduh laporan semua user beserta klasifikasi mata terbaru mereka dalam format CSV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 40),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _status.contains('Gagal') ? Colors.red : Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Memproses...' : 'Unduh Data (CSV)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
