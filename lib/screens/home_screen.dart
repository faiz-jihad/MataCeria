// lib/screens/home_screen.dart (IMPROVED VERSION)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/eye_refraction_provider.dart';
import '../services/api_service.dart';
import '../providers/eye_rest_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/eye_rest_dialog.dart';
import '../widgets/quick_detect_dialog.dart';
import '../utils/constants.dart';
import '../utils/analytics_helper.dart';
import 'home_tab.dart';
import 'prediction_tab.dart';
import 'profile_tab.dart';
import '../l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final AnimationController _pageTransitionController;
  late final List<AnimationController> _bottomNavControllers;
  late final PageController _pageController;
  
  bool _mlServiceAvailable = false;
  bool _isCheckingService = true;
  int _unreadChatCount = 0;
  late final List<Widget> _screens;
  
  // Tab controllers
  final Map<int, GlobalKey> _tabKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreens();
    _initializeControllers();
    _loadInitialData();
    _setupEventListeners();
  }

  void _initializeScreens() {
    _screens = [
      HomeTab(
        key: _tabKeys[0],
        onTabSelected: _onNavItemTapped,
      ),
      const PredictionTab(key: ValueKey('prediction_tab')),
      const ProfileTab(key: ValueKey('profile_tab')),
    ];
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _initializeControllers() {
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _bottomNavControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _checkMLService(),
      _loadUnreadChatCount(),
    ]);
  }

  void _setupEventListeners() {
    // Listen for eye rest reminders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eyeRestProvider = Provider.of<EyeRestProvider>(context, listen: false);
      eyeRestProvider.addListener(_handleEyeRestAlert);
    });
  }

  void _handleEyeRestAlert() {
    final eyeRestProvider = Provider.of<EyeRestProvider>(context, listen: false);
    if (eyeRestProvider.shouldShowAlert && mounted) {
      _showEyeRestDialog(context, eyeRestProvider);
    }
  }

  Future<void> _checkMLService() async {
    if (!mounted) return;
    
    setState(() => _isCheckingService = true);
    
    try {
      final mlProvider = Provider.of<EyeRefractionProvider>(
        context,
        listen: false,
      );
      final available = await mlProvider.checkMLHealth();
      
      if (mounted) {
        setState(() {
          _mlServiceAvailable = available;
          _isCheckingService = false;
        });
        
        // Track service availability
        AnalyticsHelper.trackEvent('ml_service_check', {
          'available': available,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mlServiceAvailable = false;
          _isCheckingService = false;
        });
      }
    }
  }

  Future<void> _loadUnreadChatCount() async {
    try {
      final count = await ApiService().getUnreadChatCount();
      if (mounted) {
        setState(() => _unreadChatCount = count);
      }
    } catch (e) {
      // Silently fail - chat feature is optional
      debugPrint('Failed to load unread chat count: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _refreshData();
        break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
      }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _checkMLService(),
      _loadUnreadChatCount(),
    ]);
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _pageController.dispose();
    for (var controller in _bottomNavControllers) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    // Animate bottom nav icon
    _bottomNavControllers[index].forward().then((_) {
      _bottomNavControllers[index].reverse();
    });
    
    // Animate page transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    
    setState(() => _selectedIndex = index);
    
    // Track navigation
    AnalyticsHelper.trackScreenView(_getScreenName(index));
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    
    setState(() => _selectedIndex = index);
    
    // Track navigation
    AnalyticsHelper.trackScreenView(_getScreenName(index));
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0: return 'home_tab';
      case 1: return 'prediction_tab';
      case 2: return 'profile_tab';
      default: return 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          items: _buildNavItems(),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex != 1) return null;
    
    return FloatingActionButton.extended(
      onPressed: () => _showQuickDetectDialog(context),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: Text('new_report'.tr(context)),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  List<CustomNavItem> _buildNavItems() {
    return [
      CustomNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'nav_home'.tr(context),
      ),
      CustomNavItem(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
        label: 'nav_history'.tr(context),
        badgeCount: _unreadChatCount,
      ),
      CustomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'nav_profile'.tr(context),
      ),
    ];
  }

  void _showQuickDetectDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => QuickDetectDialog(
        mlServiceAvailable: _mlServiceAvailable,
        isCheckingService: _isCheckingService,
        onRetryCheck: _checkMLService,
      ),
    );
  }

  void _showEyeRestDialog(BuildContext context, EyeRestProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EyeRestDialog(
        onDismiss: () {
          provider.dismissAlert();
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}