// lib/providers/notification_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  static const String _reminderPrefKey = 'notification_reminders_enabled';
  static const String _emailPrefKey = 'email_updates_enabled';

  bool _reminderEnabled = true; // Default value
  bool _emailUpdatesEnabled = true; // Default value

  bool get reminderEnabled => _reminderEnabled;
  bool get emailUpdatesEnabled => _emailUpdatesEnabled;

  NotificationProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderEnabled = prefs.getBool(_reminderPrefKey) ?? true;
    _emailUpdatesEnabled = prefs.getBool(_emailPrefKey) ?? true;
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderPrefKey, value);
    _reminderEnabled = value;
    notifyListeners();
  }

  Future<void> setEmailUpdatesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailPrefKey, value);
    _emailUpdatesEnabled = value;
    notifyListeners();
  }
}