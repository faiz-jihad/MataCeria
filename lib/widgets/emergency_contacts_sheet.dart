import 'package:flutter/material.dart';
import '../models/emergency_model.dart';
import '../services/api_service.dart';

class EmergencyContactsSheet extends StatefulWidget {

  const EmergencyContactsSheet({
    super.key,
    required this.initialContacts,
    required this.onCall,
  });
  final List<EmergencyContact> initialContacts;
  final Function(EmergencyContact) onCall;

  static void show({
    required BuildContext context,
    required List<EmergencyContact> contacts,
    required Function(EmergencyContact) onCall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmergencyContactsSheet(
        initialContacts: contacts,
        onCall: onCall,
      ),
    );
  }

  @override
  State<EmergencyContactsSheet> createState() => _EmergencyContactsSheetState();
}

class _EmergencyContactsSheetState extends State<EmergencyContactsSheet> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  String _selectedRegion = 'Semua';
  List<EmergencyContact> _currentContacts = [];
  bool _isLoading = false;

  final List<String> _regions = [
    'Semua',
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Makassar',
    'Bali'
  ];

  @override
  void initState() {
    super.initState();
    _currentContacts = widget.initialContacts;
  }

  Future<void> _fetchContacts(String region) async {
    setState(() {
      _selectedRegion = region;
      _isLoading = true;
    });

    try {
      final contacts = await _apiService.getEmergencyContacts(region: region);
      setState(() {
        _currentContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui data wilayah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentContacts
        .where((c) => _searchQuery.isEmpty || c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRegionSelector(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildContactItem(filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.emergency, color: Colors.red.shade400, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kontak Darurat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final region = _regions[index];
          final isSelected = _selectedRegion == region;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(region),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _fetchContacts(region);
              },
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari rumah sakit...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildContactItem(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: contact.type == 'hospital' ? Colors.red.shade50 : Colors.blue.shade50,
          child: Icon(
            contact.type == 'hospital' ? Icons.local_hospital : Icons.medical_services,
            color: contact.type == 'hospital' ? Colors.red : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.address ?? ''),
            if (contact.city != null)
              Text(
                contact.city!,
                style: TextStyle(color: Colors.blue.shade400, fontSize: 12, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => widget.onCall(contact),
          icon: const Icon(Icons.phone, color: Colors.green),
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Kontak tidak ditemukan di wilayah ini',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
