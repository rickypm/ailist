import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class CacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('CacheService not initialized.  Call CacheService.init() first.');
    }
    return _prefs!;
  }

  // ============================================================
  // ONBOARDING
  // ============================================================

  static bool get isOnboardingComplete {
    return prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    await prefs.setBool(AppConstants.keyOnboardingComplete, value);
  }

  // ============================================================
  // USER CITY
  // ============================================================

  static String get userCity {
    return prefs.getString(AppConstants.keyUserCity) ?? 'Shillong';
  }

  static Future<void> setUserCity(String city) async {
    await prefs.setString(AppConstants.keyUserCity, city);
  }

  // ============================================================
  // THEME
  // ============================================================

  static String get themeMode {
    return prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String mode) async {
    await prefs.setString(AppConstants.keyThemeMode, mode);
  }

  // ============================================================
  // GENERIC METHODS
  // ============================================================

  static Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  static String? getString(String key) {
    return prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return prefs. getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await prefs. setInt(key, value);
  }

  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    await prefs.clear();
  }
}