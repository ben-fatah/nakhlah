import 'package:flutter/material.dart';

class LocaleProvider extends ValueNotifier<Locale> {
  LocaleProvider() : super(const Locale('en'));

  bool get isArabic => value.languageCode == 'ar';

  void toggleLocale() {
    value = isArabic ? const Locale('en') : const Locale('ar');
  }

  void setLocale(Locale locale) {
    value = locale;
  }
}

// Global singleton — import this wherever you need it
final localeProvider = LocaleProvider();
