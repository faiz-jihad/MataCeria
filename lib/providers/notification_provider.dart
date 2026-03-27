import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  void clearUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}
