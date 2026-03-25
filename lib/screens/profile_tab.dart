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
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../providers/theme_provider.dart';

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
      await prefs.setBool('two_factor_enabled', _twoFactorEnabled);
      await prefs.setString('selected_language', _selectedLanguage);
      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      debugPrint('Error saving settings: $e');
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

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
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
                      stops: [0.0, 0.5, 1.0],
                      colors: [
                        Color(0xFF2E5BFF), // Deep Blue
                        Color(0xFF3B82F6), // Azure Blue
                        Color(0xFF10B981), // Emerald
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Abstract Decorative Elements
                      Positioned(
                        top: -100,
                        right: -50,
                        child: _buildDecorativeCircle(300, Colors.white.withOpacity(0.08)),
                      ),
                      Positioned(
                        top: 20,
                        left: -40,
                        child: _buildDecorativeCircle(120, Colors.white.withOpacity(0.05)),
                      ),
                      Positioned(
                        bottom: 40,
                        right: 20,
                        child: _buildDecorativeCircle(80, Colors.white.withOpacity(0.03)),
                      ),
                      // Profile content
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            _buildModernProfileHeader(user),
                            const Spacer(flex: 1),
                            _buildModernStatsRow(user, mlProvider),
                            const SizedBox(height: 24),
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
          alignment: Alignment.center,
          children: [
            // Decorative Outer Ring
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            // Avatar Container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : null,
                  child: _imageFile == null
                      ? Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: -2),
                        )
                      : null,
                ),
              ),
            ),
            // Camera Edit Button
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _showChangePhotoDialog(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_enhance,
                    color: Colors.white,
                    size: 18,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildModernStatItem(
            value: '$totalDetections',
            label: 'Detections',
            icon: Icons.analytics_outlined,
            color: Colors.white,
          ),
          _buildVerticalDivider(),
          _buildModernStatItem(
            value: '$totalConsultations',
            label: 'Consults',
            icon: Icons.forum_outlined,
            color: Colors.white,
          ),
          _buildVerticalDivider(),
          _buildModernStatItem(
            value: mlProvider.serviceHealthy ? 'Online' : 'Offline',
            label: 'AI Core',
            icon: Icons.auto_awesome_outlined,
            color: mlProvider.serviceHealthy ? const Color(0xFF34D399) : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
          ],
        ),
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
          Icon(icon, color: color.withOpacity(0.9), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.0,
            ),
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
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _updateProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.save_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Save',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        _isEditing
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: items.map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.lock_person_rounded,
                      size: 18,
                      color: Colors.blue.withOpacity(0.2),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        _isEditing
            ? TextFormField(
                controller: controller,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                keyboardType: keyboardType,
                maxLines: maxLines,
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? '-' : controller.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (!_isEditing)
                      Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: Colors.blue.withOpacity(0.4),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: const Color(0xFF2563EB).withOpacity(0.1),
              checkmarkColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            );
          }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildModernSettingSection('prof_preferences'.tr(context), [
          _buildModernSettingTile(
            icon: Icons.notifications_active_outlined,
            title: 'prof_notifications'.tr(context),
            subtitle: 'Manage app alerts',
            color: const Color(0xFF6366F1),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveSettings();
              },
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          _buildModernSettingTile(
            icon: Icons.translate_rounded,
            title: 'prof_language'.tr(context),
            subtitle: Provider.of<LanguageProvider>(context).currentLanguage == 'id' ? 'Indonesia' : 'English',
            color: const Color(0xFF10B981),
            onTap: () => _showModernLanguageDialog(),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => _buildModernSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'prof_dark_mode'.tr(context),
              subtitle: themeProvider.isDarkMode ? 'Always On' : 'Adaptive',
              color: const Color(0xFF8B5CF6),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) async {
                  await themeProvider.toggleTheme(value);
                },
                activeColor: const Color(0xFF8B5CF6),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _buildModernSettingSection('prof_eye_health'.tr(context), [
          Consumer<EyeRestProvider>(
            builder: (context, eyeRest, child) => _buildModernSettingTile(
              icon: Icons.remove_red_eye_rounded,
              title: 'prof_rest_reminders'.tr(context),
              subtitle: 'Prevent eye strain',
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
              icon: Icons.hourglass_empty_rounded,
              title: 'prof_interval'.tr(context),
              subtitle: '${eyeRest.reminderIntervalMinutes} mins',
              color: const Color(0xFF0D9488),
              onTap: eyeRest.isEnabled ? () => _showEyeRestIntervalDialog(context, eyeRest) : null,
              trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _buildModernSettingSection('prof_security'.tr(context), [
          _buildModernSettingTile(
            icon: Icons.key_rounded,
            title: 'prof_password'.tr(context),
            subtitle: 'Secure your account',
            color: const Color(0xFFEF4444),
            onTap: () => _showModernChangePasswordDialog(context),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ),
          _buildModernSettingTile(
            icon: Icons.verified_user_rounded,
            title: 'prof_2fa'.tr(context),
            subtitle: _twoFactorEnabled ? 'Active' : 'Not setup',
            color: const Color(0xFFF59E0B),
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (value) async {
                setState(() => _twoFactorEnabled = value);
                await _saveSettings();
                // TODO: Sync this state with backend via User model update
                _showModernTwoFactorDialog(value);
              },
              activeColor: const Color(0xFFF59E0B),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(
              context,
              Provider.of<AuthProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text('prof_logout'.tr(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildModernSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade400,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              final isLast = index == children.length - 1;
              return Column(
                children: [
                  child,
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade50,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showEyeRestIntervalDialog(BuildContext context, EyeRestProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Reminder Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...[10, 15, 20, 30, 45, 60].map((mins) => ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text('$mins minutes', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: provider.reminderIntervalMinutes == mins
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
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

  void _showModernLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ..._languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w600)),
                value: lang,
                groupValue: Provider.of<LanguageProvider>(context, listen: false).currentLanguage == 'id' ? 'Indonesia' : 'English',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onChanged: (value) async {
                  final code = value == 'English' ? 'en' : 'id';
                  await Provider.of<LanguageProvider>(context, listen: false).setLanguage(code);
                  Navigator.pop(context);
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                _buildDialogField(
                  controller: oldPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  controller: newPasswordController,
                  label: 'New Password',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                                'Password updated successfully!',
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
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  void _showModernTwoFactorDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (enabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  enabled ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                  size: 40,
                  color: enabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                enabled ? 'Enable 2FA?' : 'Disable 2FA?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                enabled
                    ? 'Adds an extra layer of security to your account with verification codes.'
                    : 'Disabling 2FA makes your account more vulnerable. Are you sure you want to proceed?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w700)),
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
                        backgroundColor: enabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(enabled ? 'Enable' : 'Disable', style: const TextStyle(fontWeight: FontWeight.w700)),
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

  void _showChangePhotoDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
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

        // TODO: Implement backend upload when endpoint is ready
        // final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // await authProvider.uploadProfilePhoto(pickedFile);

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
