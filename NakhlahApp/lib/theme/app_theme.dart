import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralised ThemeData factory for the Nakhlah application.
///
/// Previously embedded inside `main.dart`; extracted here so that both
/// `main.dart` and any future flavour/brand overrides can share the same
/// base configuration.
abstract final class AppTheme {
  static ThemeData light(BuildContext context) {
    final textTheme = GoogleFonts.cairoTextTheme(Theme.of(context).textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.palmGreen,
        primary: AppColors.palmGreen,
        secondary: AppColors.goldenDate,
        surface: AppColors.cardWhite,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.palmGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.palmGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.palmGreen.withValues(alpha: 0.4),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          padding: const EdgeInsets.only(bottom: 6),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldenDate,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.cairo(color: AppColors.palmGreen),
        hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
        prefixIconColor: AppColors.goldenDate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.palmGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.offWhite),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
      ),
    );
  }
}
