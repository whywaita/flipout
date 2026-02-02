import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

/// Service for persisting settings to LocalStorage
class StorageService {
  static const String _settingsKey = 'flipout_settings';

  /// Save settings to LocalStorage
  static Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  /// Load settings from LocalStorage
  static Future<Settings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Settings.fromJson(json);
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  /// Clear all stored settings
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}
