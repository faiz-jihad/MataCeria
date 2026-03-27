// lib/screens/home_tab.dart (IMPROVED VERSION)

import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/emergency_model.dart';
import '../models/user_model.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/emergency_card.dart';
import '../widgets/service_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/article_card.dart';
import '../widgets/notification_sheet.dart';
import '../widgets/emergency_contacts_sheet.dart';
import '../utils/constants.dart';
import '../utils/analytics_helper.dart';
import '../utils/error_handler.dart';
import '../models/service_item.dart';
import '../widgets/articles_sheet.dart';
import '../l10n/app_strings.dart';

class HomeTab extends StatefulWidget {
  
  const HomeTab({
    super.key,
    this.onTabSelected,
  });
  final Function(int)? onTabSelected;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Services
  final ApiService _apiService = ApiService();
  
  // Data
  List<EmergencyContact> _emergencyContacts = [];
  User? _currentUser;
  int _unreadChats = 0;
  int _unreadNotifications = 0;
  io.File? _profileImage;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // State
  bool _isLoadingEmergencyContacts = true;
  bool _isRefreshing = false;
  bool _isInitialized = false;
  
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // Cache
  final Map<String, dynamic> _cache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _setupKeyboardDismissal();
  }
  
  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    );
    _fadeAnimationController.forward();
  }
  
  void _setupKeyboardDismissal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Dismiss keyboard when tapping outside
      GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: const SizedBox.shrink(),
      );
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    try {
      await Future.wait([
        _loadUserData(),
        _loadEmergencyContacts(),
        _loadUnreadChats(),
        _loadNotificationCount(),
        _loadProfileImage(),
      ]);
    } catch (e) {
      ErrorHandler.handleError(e, context);
    }
  }
  
  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _currentUser = authProvider.user;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && io.File(imagePath).existsSync() && mounted) {
        setState(() {
          _profileImage = io.File(imagePath);
        });
      }
    } catch (e) {
      // Silently fail - image loading is not critical
    }
  }

  Future<void> _loadEmergencyContacts() async {
    if (!mounted) return;
    
    setState(() => _isLoadingEmergencyContacts = true);
    
    try {
      final contacts = await _apiService.getEmergencyContacts().timeout(
        const Duration(seconds: 10),
        onTimeout: () => _getCachedContacts(),
      );
      
      if (mounted) {
        setState(() {
          _emergencyContacts = contacts;
          _isLoadingEmergencyContacts = false;
        });
        
        // Cache contacts for offline use
        _cacheEmergencyContacts(contacts);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmergencyContacts = false);
        ErrorHandler.showErrorSnackBar(
          context,
          'article_error'.tr(context),
        );
      }
    }
  }
  
  Future<List<EmergencyContact>> _getCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_emergency_contacts');
      if (cached != null) {
        // Parse cached data
        // Implementation depends on your serialization method
        return [];
      }
    } catch (e) {
      // Fallback to empty list
    }
    return [];
  }
  
  Future<void> _cacheEmergencyContacts(List<EmergencyContact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cache contacts for offline use
      // Implementation depends on your serialization method
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  Future<void> _loadUnreadChats() async {
    try {
      final count = await _apiService.getUnreadChatCount().timeout(
        const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() => _unreadChats = count);
      }
    } catch (e) {
      // Silently fail - chat count is not critical
      if (mounted) setState(() => _unreadChats = 0);
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await _apiService.getNotifications().timeout(
        const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() => _unreadNotifications = notifications.length);
      }
    } catch (e) {
      // Silently fail - notification count is not critical
      if (mounted) setState(() => _unreadNotifications = 0);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        displacement: 40,
        edgeOffset: 20,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildServicesSection(),
                  if (_currentUser?.role == 'admin') _buildAdminSection(),
                  const SizedBox(height: 24),
                  _buildPromoBanner(),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(),
                  const SizedBox(height: 24),
                  _buildEmergencySection(),
                  const SizedBox(height: 24),
                  _buildArticleSection(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        title: _buildAppBarTitle(),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
        collapseMode: CollapseMode.pin,
      ),
      actions: [
        _buildNotificationIcon(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👋 MataCeria!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _currentUser?.name ?? 'Pengguna',
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        if (_profileImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.file(
              _profileImage!,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showNotificationsSheet(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
          ),
          if (_unreadNotifications > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'search_hint'.tr(context), // Add to AppStrings
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      ServiceItem(
        key: 'detect',
        title: 'btn_detect'.tr(context),
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF2563EB),
        onTap: () => Navigator.pushNamed(context, '/refraction_test'),
      ),
      ServiceItem(
        key: 'consult',
        title: 'btn_consult'.tr(context),
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFF59E0B),
        badgeCount: _unreadChats,
        onTap: () => Navigator.pushNamed(context, '/chat'),
      ),
      ServiceItem(
        key: 'tips',
        title: 'btn_tips'.tr(context),
        icon: Icons.article_outlined,
        color: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF0284C7),
        onTap: () => _showArticlesSheet(),
      ),
      ServiceItem(
        key: 'location',
        title: 'btn_location'.tr(context),
        icon: Icons.location_on_outlined,
        color: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFEF4444),
        onTap: () => _showEmergencyContactsSheet(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'services_title'.tr(context),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: services.map((service) => ServiceCard(service: service)).toList(),
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Admin Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.purple.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF581C87),
                      ),
                    ),
                    Text(
                      'Kelola pengguna, laporan, dan konten',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Buka'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDBF4F9), Color(0xFFB8E4ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 180,
                  child: Text(
                    'Dapatkan Layanan Refraksi Terbaik',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Konsultasikan kesehatan mata Anda\ndengan AI kami 24/7.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/refraction_test'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Coba Sekarang',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 12, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/doctor_illustration.png',
                fit: BoxFit.cover,
                width: 120,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  color: Colors.blue.shade200,
                  child: const Icon(Icons.medical_services, size: 60, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'activities_title'.tr(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => widget.onTabSelected?.call(1),
              child: Text(
                'see_all'.tr(context),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _apiService.getUserActivities(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CustomLoadingIndicator()),
              );
            }
            
            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'activities_empty'.tr(context),
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'activities_subtitle'.tr(context),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: activities.take(2).map((activity) {
                return ActivityCard(
                  title: activity['title'] ?? 'Aktivitas',
                  subtitle: activity['description'] ?? '',
                  time: activity['time'] ?? 'Baru saja',
                  type: activity['type'] ?? 'info',
                  onTap: () => _handleActivityTap(activity),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'info';
    if (type == 'detection') {
      Navigator.pushNamed(context, '/report-detail', arguments: activity['id']);
    } else if (type == 'consultation') {
      Navigator.pushNamed(context, '/chat-detail', arguments: activity['id']);
    }
    AnalyticsHelper.trackEvent('activity_tapped', {'type': type});
  }

  Widget _buildEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'emergency_title'.tr(context),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_emergencyContacts.isNotEmpty)
                TextButton(
                  onPressed: _showEmergencyContactsSheet,
                  child: Text('see_all'.tr(context)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingEmergencyContacts)
          const SizedBox(
            height: 140,
            child: Center(child: CustomLoadingIndicator()),
          )
        else if (_emergencyContacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'emergency_none'.tr(context),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/add-emergency-contact'),
                    child: Text('emergency_add'.tr(context)),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emergencyContacts.length > 5 ? 5 : _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return EmergencyCard(
                  contact: contact,
                  index: index,
                  onCall: () => _showCallDialog(contact),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildArticleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'article_title'.tr(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showArticlesSheet,
              child: Text('see_all'.tr(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _apiService.getArticles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SkeletonLoader(
                      width: 280,
                      height: 220,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            }
            
            final articles = snapshot.data ?? [];
            if (articles.isEmpty) {
              return _buildStaticTipsFallback();
            }
            
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ArticleCard(
                    article: article,
                    index: index,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/article-detail',
                      arguments: article,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStaticTipsFallback() {
    final tips = [
      {'title': 'Istirahatkan Mata', 'icon': Icons.visibility_off, 'color': Colors.blue},
      {'title': 'Periksa Rutin', 'icon': Icons.event_available, 'color': Colors.orange},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      await Future.wait([
        _loadEmergencyContacts(),
        _loadUnreadChats(),
        _loadNotificationCount(),
      ]);
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Data berhasil diperbarui',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Gagal memperbarui data',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showNotificationsSheet() {
    NotificationSheet.show(
      context: context,
      unreadCount: _unreadNotifications,
      onReadAll: () {
        setState(() => _unreadNotifications = 0);
        AnalyticsHelper.trackEvent('notifications_read_all');
      },
    );
  }

  void _showEmergencyContactsSheet() {
    EmergencyContactsSheet.show(
      context: context,
      contacts: _emergencyContacts,
      onCall: _showCallDialog,
    );
  }

  void _showArticlesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ArticlesSheet(
        apiService: _apiService,
        onArticleTap: (article) => Navigator.pushNamed(
          context,
          '/article-detail',
          arguments: article,
        ),
      ),
    );
  }

  void _showCallDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: Text('Hubungi nomor ${contact.phone}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final launchUri = Uri(scheme: 'tel', path: contact.phone);
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
                AnalyticsHelper.trackEvent('emergency_call', {
                  'contact': contact.name,
                  'type': contact.type,
                });
              } else {
                ErrorHandler.showErrorSnackBar(
                  context,
                  'Gagal melakukan panggilan ke ${contact.phone}',
                );
              }
            },
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Hubungi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}