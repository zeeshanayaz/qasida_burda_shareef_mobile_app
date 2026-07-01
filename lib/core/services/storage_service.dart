import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main.dart');
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeArabicKey = 'font_size_arabic';
  static const String _fontSizeTranslationKey = 'font_size_translation';
  static const String _lastReadVerseKey = 'last_read_verse';

  // Theme settings
  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<bool> setThemeMode(String value) async {
    return await _prefs.setString(_themeModeKey, value);
  }

  // Font Sizes
  double getArabicFontSize() {
    return _prefs.getDouble(_fontSizeArabicKey) ?? 24.0;
  }

  Future<bool> setArabicFontSize(double value) async {
    return await _prefs.setDouble(_fontSizeArabicKey, value);
  }

  double getTranslationFontSize() {
    return _prefs.getDouble(_fontSizeTranslationKey) ?? 16.0;
  }

  Future<bool> setTranslationFontSize(double value) async {
    return await _prefs.setDouble(_fontSizeTranslationKey, value);
  }

  // Resume Reading bookmark
  int? getLastReadVerse() {
    return _prefs.getInt(_lastReadVerseKey);
  }

  Future<bool> setLastReadVerse(int verseId) async {
    return await _prefs.setInt(_lastReadVerseKey, verseId);
  }

  // Generic methods
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
