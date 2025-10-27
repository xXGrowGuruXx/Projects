import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _languageKey = 'language';
  static const String _themeModeKey = 'theme_mode';
  static const String _cloudBackupKey = 'cloud_backup';
  
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _cloudBackupEnabled = false;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get cloudBackupEnabled => _cloudBackupEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Language
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      _locale = Locale(languageCode);
    } else {
      _locale = null; // System default
    }
    
    // Theme Mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    // Cloud Backup
    _cloudBackupEnabled = prefs.getBool(_cloudBackupKey) ?? false;
    
    notifyListeners();
  }

  Future<void> setLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (languageCode == null) {
      await prefs.remove(_languageKey);
      _locale = null;
    } else {
      await prefs.setString(_languageKey, languageCode);
      _locale = Locale(languageCode);
    }
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    _themeMode = mode;
    notifyListeners();
  }
  
  Future<void> setCloudBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudBackupKey, enabled);
    _cloudBackupEnabled = enabled;
    notifyListeners();
  }
}
