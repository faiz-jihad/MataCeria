import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomBottomNavBar extends StatelessWidget {

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryBlue,
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
          items: items.map((item) => item.toBottomNavItem(currentIndex)).toList(),
        ),
      ),
    );
  }
}

class CustomNavItem {

  CustomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  BottomNavigationBarItem toBottomNavItem(int currentIndex) {
    return BottomNavigationBarItem(
      icon: _buildIcon(icon, isActive: false),
      activeIcon: _buildIcon(activeIcon, isActive: true),
      label: label,
    );
  }

  Widget _buildIcon(IconData iconData, {required bool isActive}) {
    if (badgeCount != null && badgeCount! > 0 && !isActive) {
      return Badge(
        label: Text('$badgeCount'),
        child: Icon(iconData),
      );
    }
    return Icon(iconData);
  }
}
