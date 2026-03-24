// lib/screens/home_screen.dart (FIXED VERSION)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/eye_refraction_provider.dart';
import '../services/api_service.dart';
import '../providers/eye_rest_provider.dart';
import 'home_tab.dart';
import 'prediction_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _bottomNavControllers;

  bool _mlServiceAvailable = false;
  bool _isCheckingService = true;
  int _unreadChatCount = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(onTabSelected: _onNavItemTapped),
      const PredictionTab(),
      const ProfileTab(),
    ];
    _initAnimations();
    _checkMLService();
    _loadUnreadChatCount();
    
    // Listen for Eye Rest reminders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupEyeRestListener();
    });
  }

  void _setupEyeRestListener() {
    final eyeRestProvider = Provider.of<EyeRestProvider>(context, listen: false);
    eyeRestProvider.addListener(() {
      if (eyeRestProvider.shouldShowAlert && mounted) {
        _showEyeRestDialog(context, eyeRestProvider);
      }
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _bottomNavControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _animationController.forward();
  }

  Future<void> _checkMLService() async {
    setState(() => _isCheckingService = true);
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
    }
  }

  Future<void> _loadUnreadChatCount() async {
    try {
      final count = await ApiService().getUnreadChatCount();
      if (mounted) {
        setState(() {
          _unreadChatCount = count;
        });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _bottomNavControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    _bottomNavControllers[index].forward().then((_) {
      _bottomNavControllers[index].reverse();
    });

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: _screens[_selectedIndex],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () => _showQuickDetectDialog(context),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('New Report'),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            _buildAnimatedNavItem(
              index: 0,
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Home',
            ),
            _buildAnimatedNavItem(
              index: 1,
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: 'Report',
            ),
            _buildAnimatedNavItem(
              index: 2,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildAnimatedNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _bottomNavControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_bottomNavControllers[index].value * 0.2),
            child: Icon(_selectedIndex == index ? activeIcon : icon),
          );
        },
      ),
      label: label,
    );
  }

  void _showQuickDetectDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Create New Report',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogOption(
                    icon: Icons.camera_alt,
                    color: const Color(0xFF2563EB),
                    title: 'Kamera',
                    subtitle: 'Ambil foto langsung dengan kamera',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/camera');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDialogOption(
                    icon: Icons.photo_library,
                    color: const Color(0xFF10B981),
                    title: 'Galeri',
                    subtitle: 'Pilih foto dari galeri',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/camera');
                    },
                  ),
                  if (_isCheckingService)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!_mlServiceAvailable) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode offline: Hasil akan menggunakan data contoh. Fitur AI tidak tersedia.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Tutup'),
                ),
                if (!_mlServiceAvailable)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _checkMLService();
                    },
                    child: const Text('Cek Koneksi'),
                  ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showEyeRestDialog(BuildContext context, EyeRestProvider provider) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Row(
          children: [
            Icon(Icons.remove_red_eye, color: Color(0xFF2563EB), size: 30),
            SizedBox(width: 12),
            Text('Waktunya Istirahat!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Anda sudah menggunakan aplikasi cukup lama. Ikuti aturan 20-20-20:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'Setiap 20 menit, lihatlah objek sejauh 20 kaki (6 meter) selama 20 detik.',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.dismissAlert();
              Navigator.pop(context);
            },
            child: const Text('Sudah Istirahat'),
          ),
        ],
      ),
    );
  }
}