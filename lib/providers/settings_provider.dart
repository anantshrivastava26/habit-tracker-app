import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode = 'dark_mode';
  static const _keyReminderNotifications = 'notifications_enabled';
  static const _keyCompletionNotifications =
      'completion_notifications_enabled';
  static const _keyMilestoneNotifications = 'milestone_notifications_enabled';

  bool _darkMode = false;
  bool _reminderNotificationsEnabled = true;
  bool _completionNotificationsEnabled = true;
  bool _milestoneNotificationsEnabled = true;

  bool get darkMode => _darkMode;
  bool get reminderNotificationsEnabled => _reminderNotificationsEnabled;
  bool get completionNotificationsEnabled => _completionNotificationsEnabled;
  bool get milestoneNotificationsEnabled => _milestoneNotificationsEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _reminderNotificationsEnabled =
        prefs.getBool(_keyReminderNotifications) ?? true;
    _completionNotificationsEnabled =
        prefs.getBool(_keyCompletionNotifications) ?? true;
    _milestoneNotificationsEnabled =
        prefs.getBool(_keyMilestoneNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setReminderNotificationsEnabled(bool value) async {
    _reminderNotificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderNotifications, value);
  }

  Future<void> setCompletionNotificationsEnabled(bool value) async {
    _completionNotificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompletionNotifications, value);
  }

  Future<void> setMilestoneNotificationsEnabled(bool value) async {
    _milestoneNotificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMilestoneNotifications, value);
  }
}
