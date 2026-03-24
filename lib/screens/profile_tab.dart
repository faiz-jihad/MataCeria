import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io show File;
import '../providers/auth_provider.dart';
import '../providers/eye_refraction_provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../providers/eye_rest_provider.dart';


class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;

  // Settings State
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _twoFactorEnabled = false;
  String _selectedLanguage = 'Indonesia';
  final List<String> _languages = ['Indonesia', 'English', '中文', 'العربية'];

  // Profile Data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _visionTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Laki-laki';
  String _education = 'SMA';
  String _occupation = 'Pelajar/Mahasiswa';
  List<String> _visionConcerns = [];
  io.File? _imageFile;

  bool _isSavingProfile = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
    _loadUserData();
    // Check AI service health on tab load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EyeRefractionProvider>(
        context,
        listen: false,
      ).checkMLHealth();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _visionTypeController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _visionTypeController.text = user.visionType ?? '';
      _allergiesController.text = user.allergies ?? '';
      _medicalHistoryController.text = user.medicalHistory ?? '';
      _visionConcerns = List<String>.from(user.visionConcerns ?? []);
      _ageController.text = user.age?.toString() ?? '';
      _gender = user.gender ?? 'Laki-laki';
      _education = user.education ?? 'SMA';
      _occupation = user.occupation ?? 'Pelajar/Mahasiswa';
    }

    // Load locally persisted profile image path
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && io.File(imagePath).existsSync()) {
        setState(() {
          _imageFile = io.File(imagePath);
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
        _selectedLanguage = prefs.getString('selected_language') ?? 'Indonesia';
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
      await prefs.setBool('two_factor_enabled', _twoFactorEnabled);
      await prefs.setString('selected_language', _selectedLanguage);
      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save settings');
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateUserProfile({
        'nama_lengkap': name,
        'umur': int.tryParse(_ageController.text),
        'kelamin': _gender,
        'jenjang_pendidikan': _education,
        'status_pekerjaan': _occupation,
        'phone': _phoneController.text.trim(),
        'vision_type': _visionTypeController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'medical_history': _medicalHistoryController.text.trim(),
        'vision_concerns': _visionConcerns,
      });

      if (success && mounted) {
        _showSuccessSnackBar('Profile updated successfully');
        _loadUserData();
        setState(() => _isEditing = false);
      } else if (mounted) {
        _showErrorSnackBar(
          authProvider.errorMessage ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mlProvider = Provider.of<EyeRefractionProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              floating: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2563EB), // Blue 600
                        Color(0xFF3B82F6), // Blue 500
                        Color(0xFF10B981), // Emerald 500
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated background patterns
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Profile content
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            _buildModernProfileHeader(user),
                            const Spacer(),
                            _buildModernStatsRow(user, mlProvider),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                _buildModernActionButton(
                  icon: Icons.edit_outlined,
                  onPressed: () => setState(() => _isEditing = true),
                  showBadge: false,
                ),
                _buildModernActionButton(
                  icon: Icons.logout_outlined,
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  showBadge: false,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Profile', icon: Icon(Icons.person_outline)),
                      Tab(
                        text: 'Settings',
                        icon: Icon(Icons.settings_outlined),
                      ),
                    ],
                    indicatorColor: const Color(0xFF6366F1),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF6366F1),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildModernInfoTab(user, mlProvider),
                _buildModernSettingsTab(),
              ],
            ),
            if (_isSavingProfile)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(User? user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showChangePhotoDialog(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_isEditing)
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: 'Your name',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _updateProfile,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadUserData();
                },
              ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'email@example.com',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildModernStatsRow(User? user, EyeRefractionProvider mlProvider) {
    final totalDetections = user?.totalDetections ?? 0;
    final totalConsultations = user?.totalConsultations ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildModernStatItem(
            value: '$totalDetections',
            label: 'Detections',
            icon: Icons.visibility_outlined,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildModernStatItem(
            value: '$totalConsultations',
            label: 'Consultations',
            icon: Icons.chat_outlined,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildModernStatItem(
            value: mlProvider.serviceHealthy ? 'Online' : 'Offline',
            label: 'AI Status',
            icon: Icons.auto_awesome,
            color: mlProvider.serviceHealthy ? const Color(0xFF10B981) : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool showBadge,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: Icon(icon, color: Colors.white, size: 20),
              onPressed: onPressed,
            ),
          ),
          if (showBadge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTab(User? user, EyeRefractionProvider mlProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
            child: Column(
              children: [
                _buildModernEditableField(
                  label: 'Full Name',
                  controller: _nameController,
                  hint: 'Enter your full name',
                ),
                const SizedBox(height: 16),
                _buildModernInfoField(
                  label: 'Email Address',
                  value: user?.email ?? '-',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildModernEditableField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildModernEditableField(
                  label: 'Umur',
                  controller: _ageController,
                  hint: 'Masukkan umur',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildModernDropdownField(
                  label: 'Jenis Kelamin',
                  value: _gender,
                  items: ['Laki-laki', 'Perempuan'],
                  onChanged: (val) => setState(() => _gender = val!),
                ),
                const SizedBox(height: 16),
                _buildModernDropdownField(
                  label: 'Jenjang Pendidikan',
                  value: _education,
                  items: ['SD', 'SMP', 'SMA', 'D3', 'D4/S1', 'S2/S3', 'Lainnya'],
                  onChanged: (val) => setState(() => _education = val!),
                ),
                const SizedBox(height: 16),
                _buildModernDropdownField(
                  label: 'Status Pekerjaan',
                  value: _occupation,
                  items: ['Pelajar/Mahasiswa', 'Karyawan Swasta', 'PNS', 'Wiraswasta', 'Lainnya'],
                  onChanged: (val) => setState(() => _occupation = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildModernCard(
            title: 'Eye Health Information',
            icon: Icons.visibility_outlined,
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
            child: Column(
              children: [
                _buildModernEditableField(
                  label: 'Vision Type',
                  controller: _visionTypeController,
                  hint: 'Normal, nearsighted, farsighted, etc.',
                ),
                const SizedBox(height: 16),
                _buildModernChipsField(
                  label: 'Vision Concerns',
                  selected: _visionConcerns,
                  options: [
                    'Blurry vision',
                    'Headaches',
                    'Dry eyes',
                    'Glare',
                    'Eye strain',
                    'Double vision',
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernEditableField(
                  label: 'Allergies',
                  controller: _allergiesController,
                  hint: 'Any eye allergies',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildModernEditableField(
                  label: 'Medical History',
                  controller: _medicalHistoryController,
                  hint: 'Previous eye conditions',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildModernActivitySection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    items: items.map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    ),
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildModernEditableField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: keyboardType,
                maxLines: maxLines,
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? '-' : controller.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (!_isEditing)
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildModernInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernChipsField({
    required String label,
    required List<String> selected,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: _isEditing
                  ? (selected_) {
                      setState(() {
                        if (selected_) {
                          _visionConcerns.add(option);
                        } else {
                          _visionConcerns.remove(option);
                        }
                      });
                    }
                  : null,
              backgroundColor: Colors.grey.shade50,
              selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
              checkmarkColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade700,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
                width: 1,
              ),
            );
          }).toList(),
        ),
        if (!_isEditing && selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '-',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }

  Widget _buildModernActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<List<dynamic>>(
              future: ApiService().getUserActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No activities yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }
                final activities = snapshot.data!;
                return Column(
                  children: activities.take(3).map((activity) {
                    return Column(
                      children: [
                        _buildModernActivityItem(
                          title: activity['title'] ?? 'Activity',
                          description: activity['description'] ?? '',
                          icon: _getActivityIcon(activity['type']),
                          color: _getActivityColor(activity['type']),
                          time: activity['time'] ?? 'Just now',
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActivityItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    if (type == null) return Icons.notifications_outlined;
    switch (type.toLowerCase()) {
      case 'detection':
      case 'refraction':
        return Icons.camera_alt_outlined;
      case 'consultation':
      case 'chat':
        return Icons.chat_outlined;
      case 'article':
      case 'info':
        return Icons.article_outlined;
      case 'update':
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getActivityColor(String? type) {
    if (type == null) return Colors.orange;
    switch (type.toLowerCase()) {
      case 'detection':
      case 'refraction':
        return const Color(0xFF6366F1);
      case 'consultation':
      case 'chat':
        return const Color(0xFF10B981);
      case 'article':
      case 'info':
        return const Color(0xFF8B5CF6);
      case 'update':
      case 'profile':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  // ==================== MODERN SETTINGS TAB ====================
  Widget _buildModernSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildModernSettingSection('Preferences', [
          _buildModernSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Receive app notifications',
            color: const Color(0xFF6366F1),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveSettings();
                _showSuccessSnackBar(
                  'Notifications ${value ? 'enabled' : 'disabled'}',
                );
              },
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          _buildModernSettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _selectedLanguage,
            color: const Color(0xFF10B981),
            onTap: () => _showModernLanguageDialog(),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _buildModernSettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: _darkModeEnabled ? 'On' : 'Off',
            color: const Color(0xFF8B5CF6),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) async {
                setState(() => _darkModeEnabled = value);
                await _saveSettings();
                _showSuccessSnackBar(
                  'Dark mode ${value ? 'enabled' : 'disabled'}',
                );
              },
              activeColor: const Color(0xFF8B5CF6),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildModernSettingSection('Eye Health', [
          Consumer<EyeRestProvider>(
            builder: (context, eyeRest, child) => _buildModernSettingTile(
              icon: Icons.remove_red_eye_outlined,
              title: 'Eye Rest Reminders',
              subtitle: 'Remind me to take a break',
              color: const Color(0xFF2563EB),
              trailing: Switch(
                value: eyeRest.isEnabled,
                onChanged: (value) => eyeRest.toggleEnabled(value),
                activeColor: const Color(0xFF2563EB),
              ),
            ),
          ),
          Consumer<EyeRestProvider>(
            builder: (context, eyeRest, child) => _buildModernSettingTile(
              icon: Icons.timer_outlined,
              title: 'Reminder Interval',
              subtitle: '${eyeRest.reminderIntervalMinutes} minutes',
              color: const Color(0xFF10B981),
              onTap: eyeRest.isEnabled ? () => _showEyeRestIntervalDialog(context, eyeRest) : null,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildModernSettingSection('Security', [
          _buildModernSettingTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            color: const Color(0xFFEF4444),
            onTap: () => _showModernChangePasswordDialog(context),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _buildModernSettingTile(
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            subtitle: _twoFactorEnabled ? 'Enabled' : 'Disabled',
            color: const Color(0xFFF59E0B),
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (value) async {
                setState(() => _twoFactorEnabled = value);
                await _saveSettings();
                _showModernTwoFactorDialog(value);
              },
              activeColor: const Color(0xFFF59E0B),
            ),
          ),
          _buildModernSettingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            color: const Color(0xFF06B6D4),
            onTap: () => _showModernPrivacyPolicyDialog(),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ]),
        const SizedBox(height: 20),
        _buildModernSettingSection('Support', [
          _buildModernSettingTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'FAQs and guides',
            color: const Color(0xFF8B5CF6),
            onTap: () => _showModernHelpCenterDialog(),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _buildModernSettingTile(
            icon: Icons.chat_outlined,
            title: 'Contact Us',
            subtitle: 'Chat with support team',
            color: const Color(0xFF10B981),
            onTap: () => _showModernContactUsDialog(),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          _buildModernSettingTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            color: const Color(0xFF6B7280),
            onTap: () => _showModernAboutDialog(),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ]),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(
              context,
              Provider.of<AuthProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Log Out', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildModernSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModernSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showEyeRestIntervalDialog(BuildContext context, EyeRestProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Reminder Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[10, 15, 20, 30, 45, 60].map((mins) => ListTile(
                  title: Text('$mins minutes'),
                  trailing: provider.reminderIntervalMinutes == mins
                      ? const Icon(Icons.check, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    provider.setInterval(mins);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  // Modern Dialog Methods
  void _showModernLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: _selectedLanguage,
                onChanged: (value) async {
                  setState(() => _selectedLanguage = value!);
                  Navigator.pop(context);
                  await _saveSettings();
                  _showSuccessSnackBar('Language changed to $value');
                },
                activeColor: const Color(0xFF6366F1),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showModernChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () async {
                            final oldPass = oldPasswordController.text.trim();
                            final newPass = newPasswordController.text.trim();
                            final confirmPass = confirmPasswordController.text
                                .trim();

                            if (oldPass.isEmpty ||
                                newPass.isEmpty ||
                                confirmPass.isEmpty) {
                              _showErrorSnackBar('Please fill all fields');
                              return;
                            }
                            if (newPass != confirmPass) {
                              _showErrorSnackBar('Passwords do not match');
                              return;
                            }
                            if (newPass.length < 6) {
                              _showErrorSnackBar(
                                'Password must be at least 6 characters',
                              );
                              return;
                            }

                            setState(() => isSubmitting = true);
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final success = await authProvider.changePassword(
                              oldPass,
                              newPass,
                            );
                            setState(() => isSubmitting = false);

                            if (success && mounted) {
                              Navigator.pop(context);
                              _showSuccessSnackBar(
                                'Password changed successfully!',
                              );
                            } else if (mounted) {
                              _showErrorSnackBar(
                                authProvider.errorMessage ??
                                    'Failed to change password',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Update Password'),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showModernPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Information We Collect:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• User profile data\n• Eye detection history\n• Consultation records\n• Device information',
              ),
              const SizedBox(height: 16),
              const Text(
                'How We Use Your Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Provide eye refraction services\n• Improve AI accuracy\n• Personalize recommendations\n• Customer support',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernTwoFactorDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.security : Icons.security_outlined,
                size: 60,
                color: enabled
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),
              Text(
                enabled ? 'Enable 2FA?' : 'Disable 2FA?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enabled
                    ? 'Two-factor authentication adds an extra layer of security to your account.'
                    : 'Are you sure you want to disable two-factor authentication? Your account will be less secure.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _saveSettings();
                        _showSuccessSnackBar(
                          enabled
                              ? 'Two-factor authentication enabled'
                              : 'Two-factor authentication disabled',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(enabled ? 'Enable' : 'Disable'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernHelpCenterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help Center',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModernHelpItem(
              icon: Icons.help_outline,
              title: 'Frequently Asked Questions',
              subtitle: 'Find answers to common questions',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Opening FAQ');
              },
            ),
            _buildModernHelpItem(
              icon: Icons.video_library_outlined,
              title: 'Video Tutorials',
              subtitle: 'Watch step-by-step guides',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Opening tutorials');
              },
            ),
            _buildModernHelpItem(
              icon: Icons.article_outlined,
              title: 'User Guide',
              subtitle: 'Read detailed documentation',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Opening user guide');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showModernContactUsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModernContactItem(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'support@eyerefraksi.com',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Opening email');
              },
            ),
            _buildModernContactItem(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+62 812-3456-7890',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Calling support');
              },
            ),
            _buildModernContactItem(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: '24/7 support available',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showModernAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eye Refraction System',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI-powered eye refraction detection system for early diagnosis of vision disorders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '© 2025 Eye Refraction System',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePhotoDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Update Profile Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a new photo for your profile',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              title: const Text('Take Photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF10B981),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text('Remove Photo'),
                onTap: () async {
                  setState(() => _imageFile = null);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image_path');
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Profile photo removed');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    setState(() => _isImageUploading = true);

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (!kIsWeb) {
            _imageFile = io.File(pickedFile.path);
          }
        });

        // Persist image path locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', pickedFile.path);

        _showSuccessSnackBar('Profile photo updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    } finally {
      setState(() => _isImageUploading = false);
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 60, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'Log Out',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
