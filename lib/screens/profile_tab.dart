// lib/screens/profile_tab.dart (MOBILE-FRIENDLY VERSION)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../l10n/app_strings.dart';
import '../providers/theme_provider.dart';
import '../utils/screen_utils.dart';
import '../utils/constants.dart';
import '../models/prediction_model.dart';

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
  final List<String> _languages = ['Indonesia', 'English'];

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
  Prediction? _latestPrediction;

  bool _isSavingProfile = false;
  bool _isImageUploading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
    _loadUserData();
    _loadLatestPrediction();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestPrediction() async {
    try {
      final predictions = await ApiService().getPredictions();
      if (predictions.isNotEmpty && mounted) {
        setState(() {
          _latestPrediction = Prediction.fromJson(predictions.first);
        });
      }
    } catch (e) {
      debugPrint('Error loading latest prediction for profile: $e');
    }
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
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
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
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('prof_name_empty'.tr(context));
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final payload = {
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
      };
      debugPrint('UPDATE_PROFILE_DEBUG: Sending Payload: $payload');
      
      final success = await authProvider.updateUserProfile(payload);

      if (success && mounted) {
        _showSuccessSnackBar('prof_success'.tr(context));
        _loadUserData();
        setState(() => _isEditing = false);
      } else if (mounted) {
        _showErrorSnackBar(
          authProvider.errorMessage ?? 'prof_failed'.tr(context),
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
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: ScreenUtils.isSmallScreen(context) ? 260 : 280,
              pinned: true,
              floating: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.darkBlue,
                        AppColors.primaryBlue,
                        AppColors.success,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        _buildProfileHeader(user),
                        const Spacer(flex: 1),
                        _buildStatsRow(user, mlProvider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                _buildActionButton(
                  icon: Icons.logout_outlined,
                  onPressed: () => _showLogoutDialog(context, authProvider),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_outline, size: 20),
                        text: 'Profil',
                      ),
                      Tab(
                        icon: Icon(Icons.settings_outlined, size: 20),
                        text: 'Pengaturan',
                      ),
                    ],
                    indicatorColor: AppColors.primaryBlue,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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
              children: [_buildInfoTab(user, mlProvider), _buildSettingsTab()],
            ),
            if (_isSavingProfile)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showChangePhotoDialog,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 43,
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
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_enhance,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_isEditing)
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user?.name ?? 'Pengguna',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                hintText: 'Nama Anda',
              ),
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            user?.email ?? 'email@example.com',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(User? user, EyeRefractionProvider mlProvider) {
    final totalDetections = user?.totalDetections ?? 0;
    final totalConsultations = user?.totalConsultations ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: '$totalDetections',
            label: 'nav_history'.tr(context),
            icon: Icons.analytics_outlined,
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
          _buildStatItem(
            value: '$totalConsultations',
            label: 'btn_consult'.tr(context),
            icon: Icons.forum_outlined,
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
          _buildStatItem(
            value: mlProvider.serviceHealthy ? 'status_on'.tr(context) : 'offline'.tr(context),
            label: 'AI',
            icon: Icons.auto_awesome_outlined,
            valueColor: mlProvider.serviceHealthy
                ? const Color(0xFF34D399)
                : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white,
            ),
          ),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(User? user, EyeRefractionProvider mlProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'prof_information'.tr(context),
            icon: Icons.person_outline,
            gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            child: Column(
              children: [
                _buildEditableField(
                  label: 'prof_name'.tr(context),
                  controller: _nameController,
                  hint: 'name_hint'.tr(context),
                ),
                const SizedBox(height: 14),
                _buildInfoField(
                  label: 'Email',
                  value: user?.email ?? '-',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'prof_phone'.tr(context),
                  controller: _phoneController,
                  hint: 'prof_phone_hint'.tr(context),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'age_hint'.tr(context),
                  controller: _ageController,
                  hint: 'age_hint'.tr(context),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  label: 'prof_gender'.tr(context),
                  value: _gender,
                  items: ['Laki-laki', 'Perempuan'],
                  onChanged: (val) => setState(() => _gender = val!),
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  label: 'prof_education'.tr(context),
                  value: _education,
                  items: ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2/S3', 'Lainnya'],
                  onChanged: (val) => setState(() => _education = val!),
                ),
                const SizedBox(height: 14),
                _buildDropdownField(
                  label: 'prof_job'.tr(context),
                  value: _occupation,
                  items: [
                    'Pelajar/Mahasiswa',
                    'Karyawan',
                    'PNS',
                    'Wiraswasta',
                    'Lainnya',
                  ],
                  onChanged: (val) => setState(() => _occupation = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'prof_eye_health'.tr(context),
            icon: Icons.visibility_outlined,
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
            child: Column(
              children: [
                if (_latestPrediction != null) ...[
                  _buildLatestTestResult(),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableField(
                        label: 'prof_vision_type'.tr(context),
                        controller: _visionTypeController,
                        hint: 'Normal, rabun jauh, rabun dekat, dll.',
                      ),
                    ),
                    if (_isEditing && _latestPrediction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _visionTypeController.text = _latestPrediction!.className;
                            });
                          },
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: const Text('Gunakan Hasil Tes', style: TextStyle(fontSize: 10)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildChipsField(
                  label: 'prof_symptoms'.tr(context),
                  selected: _visionConcerns,
                  options: [
                    'Penglihatan kabur',
                    'Sakit kepala',
                    'Mata kering',
                    'Silau',
                    'Mata lelah',
                    'Penglihatan ganda',
                  ],
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'prof_allergies'.tr(context),
                  controller: _allergiesController,
                  hint: 'prof_allergies'.tr(context),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'prof_history'.tr(context),
                  controller: _medicalHistoryController,
                  hint: 'prof_history'.tr(context),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActivitySection(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: gradientColors[0].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: gradientColors[0], size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isEditing 
                        ? _updateProfile 
                        : () => setState(() => _isEditing = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gradientColors[0].withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEditing 
                                ? Icons.check_circle_rounded 
                                : Icons.edit_rounded,
                            size: 16,
                            color: gradientColors[0],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isEditing 
                                ? 'prof_save'.tr(context) 
                                : 'prof_edit'.tr(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: gradientColors[0],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }

  Widget _buildLatestTestResult() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xFF166534),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hasil Tes Terakhir (AI)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
                Text(
                  _latestPrediction!.className,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14532D),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _latestPrediction!.confidencePercent,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF166534).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        _isEditing
            ? TextFormField(
                controller: controller,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                keyboardType: keyboardType,
                maxLines: maxLines,
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.text.isEmpty ? '-' : controller.text,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
      ],
    );
  }

  Widget _buildInfoField({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        _isEditing
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: items.map((item) {
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ),
      ],
    );
  }

  Widget _buildChipsField({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option, style: const TextStyle(fontSize: 12)),
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
              backgroundColor: const Color(0xFFF9FAFB),
              selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
              checkmarkColor: const Color(0xFF3B82F6),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF6B7280),
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'activities_title'.tr(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<dynamic>>(
              future: ApiService().getUserActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'activities_empty'.tr(context),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final activities = snapshot.data!;
                return Column(
                  children: activities.take(3).map((activity) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getActivityColor(
                                activity['type'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getActivityIcon(activity['type']),
                              color: _getActivityColor(activity['type']),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'] ?? 'Aktivitas',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  activity['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activity['time'] ?? 'Baru',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'detection':
        return Icons.camera_alt_outlined;
      case 'consultation':
        return Icons.chat_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'detection':
        return const Color(0xFF3B82F6);
      case 'consultation':
        return const Color(0xFF10B981);
      default:
        return Colors.orange;
    }
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingSection('prof_preferences'.tr(context), [
          _buildSettingTile(
            icon: Icons.notifications_active_outlined,
            title: 'prof_notifications'.tr(context),
            subtitle: 'prof_notifications_desc'.tr(context),
            color: const Color(0xFF3B82F6),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveSettings();
              },
              activeThumbColor: const Color(0xFF3B82F6),
            ),
          ),
          _buildSettingTile(
            icon: Icons.translate_rounded,
            title: 'prof_language'.tr(context),
            subtitle: _selectedLanguage,
            color: const Color(0xFF10B981),
            onTap: () => _showLanguageDialog(),
            trailing: const Icon(Icons.chevron_right, size: 18),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'Mode Gelap',
              subtitle: themeProvider.isDarkMode ? 'Aktif' : 'Nonaktif',
              color: const Color(0xFF8B5CF6),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) async {
                  await themeProvider.toggleTheme(value);
                },
                activeThumbColor: const Color(0xFF8B5CF6),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSettingSection('prof_eye_health'.tr(context), [
          Consumer<EyeRestProvider>(
            builder: (context, eyeRest, child) => _buildSettingTile(
              icon: Icons.remove_red_eye_rounded,
              title: 'prof_rest_reminders'.tr(context),
              subtitle: eyeRest.isEnabled ? 'status_on'.tr(context) : 'status_off'.tr(context),
              color: const Color(0xFF3B82F6),
              trailing: Switch(
                value: eyeRest.isEnabled,
                onChanged: (value) => eyeRest.toggleEnabled(value),
                activeThumbColor: const Color(0xFF3B82F6),
              ),
            ),
          ),
          Consumer<EyeRestProvider>(
            builder: (context, eyeRest, child) => _buildSettingTile(
              icon: Icons.hourglass_empty_rounded,
              title: 'prof_interval'.tr(context),
              subtitle: '${eyeRest.reminderIntervalMinutes} menit',
              color: const Color(0xFF10B981),
              onTap: eyeRest.isEnabled
                  ? () => _showIntervalDialog(context, eyeRest)
                  : null,
              trailing: const Icon(Icons.chevron_right, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSettingSection('prof_security'.tr(context), [
          _buildSettingTile(
            icon: Icons.key_rounded,
            title: 'prof_password'.tr(context),
            subtitle: 'prof_password_desc'.tr(context),
            color: const Color(0xFFEF4444),
            onTap: () => _showChangePasswordDialog(context),
            trailing: const Icon(Icons.chevron_right, size: 18),
          ),
          _buildSettingTile(
            icon: Icons.verified_user_rounded,
            title: 'prof_2fa'.tr(context),
            subtitle: _twoFactorEnabled ? 'status_on'.tr(context) : 'status_off'.tr(context),
            color: const Color(0xFFF59E0B),
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (value) async {
                setState(() => _twoFactorEnabled = value);
                await _saveSettings();
                _showTwoFactorDialog(value);
              },
              activeThumbColor: const Color(0xFFF59E0B),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(
              context,
              Provider.of<AuthProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'prof_logout'.tr(context),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFEE2E2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
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
                      padding: const EdgeInsets.only(left: 60),
                      child: Divider(height: 1, color: Colors.grey.shade100),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
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
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  void _showIntervalDialog(BuildContext context, EyeRestProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Interval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...[15, 20, 30, 45, 60].map(
                (mins) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('$mins menit'),
                  trailing: provider.reminderIntervalMinutes == mins
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    provider.setInterval(mins);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Bahasa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._languages.map(
                (lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang),
                  trailing: _selectedLanguage == lang
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        )
                      : null,
                  onTap: () async {
                    setState(() => _selectedLanguage = lang);
                    await _saveSettings();
                    Navigator.pop(context);
                    _showSuccessSnackBar('Bahasa diubah ke $lang');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController =
        TextEditingController();
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
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
                  'Ubah Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
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
                              _showErrorSnackBar('Semua field harus diisi');
                              return;
                            }
                            if (newPass != confirmPass) {
                              _showErrorSnackBar('Password tidak cocok');
                              return;
                            }
                            if (newPass.length < 6) {
                              _showErrorSnackBar('Password minimal 6 karakter');
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
                              _showSuccessSnackBar('Password berhasil diubah!');
                            } else if (mounted) {
                              _showErrorSnackBar(
                                authProvider.errorMessage ??
                                    'Gagal mengubah password',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ubah Password'),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTwoFactorDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(enabled ? 'Aktifkan 2FA?' : 'Nonaktifkan 2FA?'),
        content: Text(
          enabled
              ? 'Verifikasi 2 langkah menambah keamanan akun Anda.'
              : 'Menonaktifkan 2FA membuat akun Anda kurang aman. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveSettings();
              _showSuccessSnackBar(
                enabled ? '2FA diaktifkan' : '2FA dinonaktifkan',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
            child: Text(enabled ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
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
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Foto Profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih foto baru untuk profil Anda',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
              title: const Text('Ambil Foto'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF10B981),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text('Hapus Foto'),
                onTap: () async {
                  setState(() => _imageFile = null);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image_path');
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Foto profil dihapus');
                  }
                },
              ),
            const SizedBox(height: 20),
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (!kIsWeb) {
            _imageFile = io.File(pickedFile.path);
          }
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', pickedFile.path);

        _showSuccessSnackBar('Foto profil berhasil diperbarui');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto: $e');
    } finally {
      setState(() => _isImageUploading = false);
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
