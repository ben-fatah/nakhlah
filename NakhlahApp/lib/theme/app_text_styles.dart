import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Reusable text styles for the Nakhlah application.
///
/// All styles use [GoogleFonts.cairo] for consistency with the app-wide
/// typography.
abstract final class AppTextStyles {
  // ── Headings ────────────────────────────────────────────────────────────
  static TextStyle heading1({Color? color}) => GoogleFonts.cairo(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: color ?? AppColors.brown900,
  );

  static TextStyle heading2({Color? color}) => GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: color ?? AppColors.brown900,
  );

  static TextStyle heading3({Color? color}) => GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: color ?? AppColors.brown900,
  );

  // ── Body ────────────────────────────────────────────────────────────────
  static TextStyle body({Color? color}) =>
      GoogleFonts.cairo(fontSize: 15, color: color ?? AppColors.titleColor);

  static TextStyle bodySmall({Color? color}) =>
      GoogleFonts.cairo(fontSize: 13, color: color ?? Colors.grey.shade600);

  // ── Labels & Hints ──────────────────────────────────────────────────────
  static TextStyle label({Color? color}) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.labelColor,
  );

  static TextStyle hint({Color? color}) =>
      GoogleFonts.cairo(fontSize: 14, color: color ?? AppColors.hintColor);

  // ── Buttons ─────────────────────────────────────────────────────────────
  static TextStyle button({Color? color}) => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
  );

  static TextStyle buttonSmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
  );

  // ── Chips & Badges ──────────────────────────────────────────────────────
  static TextStyle chip({Color? color, bool active = false}) =>
      GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? (active ? Colors.white : AppColors.brown900),
      );

  static TextStyle badge({Color? color}) => GoogleFonts.cairo(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.goldDark,
  );
}
