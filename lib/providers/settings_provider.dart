import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode = 'dark_mode';
  static const _keyNotifications = 'notifications_enabled';

  bool _darkMode = false;
  bool _notificationsEnabled = true;

  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }
}
