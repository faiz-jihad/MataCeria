import 'package:flutter/material.dart';

class ScreenUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 360 &&
        MediaQuery.of(context).size.width < 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) return 12;
    if (isMediumScreen(context)) return 16;
    return 20;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) return baseSize - 2;
    if (isMediumScreen(context)) return baseSize;
    return baseSize + 2;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
