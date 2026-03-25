import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user?.role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Unauthorized access')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminHeader(user?.name ?? 'Admin'),
            const SizedBox(height: 30),
            const Text(
              'Manajemen Konten',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Artikel & Tips',
              subtitle: 'Buat, edit, dan hapus artikel kesehatan',
              icon: Icons.article_rounded,
              color: const Color(0xFFE0F2FE),
              iconColor: Colors.blue.shade700,
              route: '/admin/articles',
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Kontak Darurat',
              subtitle: 'Kelola daftar RS dan Klinik Mata',
              icon: Icons.emergency_rounded,
              color: const Color(0xFFFEE2E2),
              iconColor: Colors.red.shade700,
              route: '/admin/emergency',
            ),
            const SizedBox(height: 30),
            const Text(
              'Laporan & Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Ekspor Data User',
              subtitle: 'Unduh data klasifikasi user (CSV)',
              icon: Icons.file_download_rounded,
              color: const Color(0xFFF3E8FF),
              iconColor: Colors.purple.shade700,
              route: '/admin/export',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
