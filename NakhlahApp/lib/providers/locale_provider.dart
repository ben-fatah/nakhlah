import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ValueNotifier<Locale> {
  static const _key = 'app_locale';

  LocaleProvider._internal(Locale initial) : super(initial);

  /// Loads the persisted locale from SharedPreferences.
  /// Falls back to English if no preference has been saved.
  static Future<LocaleProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final initial =
        saved != null ? Locale(saved) : const Locale('en');
    return LocaleProvider._internal(initial);
  }

  bool get isArabic => value.languageCode == 'ar';

  void toggleLocale() {
    value = isArabic ? const Locale('en') : const Locale('ar');
    _persist();
  }

  void setLocale(Locale locale) {
    value = locale;
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.languageCode);
  }
}

// Global singleton — call `await LocaleProvider.load()` in main() then assign.
final localeProvider = LocaleProvider._internal(const Locale('en'));
