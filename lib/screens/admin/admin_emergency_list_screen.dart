import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/emergency_model.dart';
import 'admin_emergency_form_screen.dart';

class AdminEmergencyListScreen extends StatefulWidget {
  const AdminEmergencyListScreen({super.key});

  @override
  State<AdminEmergencyListScreen> createState() => _AdminEmergencyListScreenState();
}

class _AdminEmergencyListScreenState extends State<AdminEmergencyListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getEmergencyContacts();
      setState(() {
        _contacts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat kontak darurat: $e');
    }
  }

  Future<void> _deleteContact(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kontak'),
        content: const Text('Apakah Anda yakin ingin menghapus kontak darurat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteEmergencyContact(id);
      if (success) {
        _showSuccessSnackBar('Kontak berhasil dihapus');
        _fetchContacts();
      } else {
        _showErrorSnackBar('Gagal menghapus kontak');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Kontak Darurat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminEmergencyFormScreen()),
          );
          if (result == true) _fetchContacts();
        },
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add_call),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Belum ada kontak darurat'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            contact.type == 'hospital' ? Icons.local_hospital : Icons.medical_services,
                            color: Colors.red.shade600,
                          ),
                        ),
                        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${contact.phone} (${contact.city ?? "-"})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminEmergencyFormScreen(contact: contact),
                                  ),
                                );
                                if (result == true) _fetchContacts();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteContact(contact.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
