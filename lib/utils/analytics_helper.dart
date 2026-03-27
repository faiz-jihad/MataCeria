import 'package:flutter/material.dart';

class AnalyticsHelper {
  static void trackEvent(String eventName, [Map<String, dynamic>? parameters]) {
    debugPrint('Analytics: $eventName - $parameters');
  }

  static void trackScreenView(String screenName) {
    debugPrint('Screen View: $screenName');
  }
}
