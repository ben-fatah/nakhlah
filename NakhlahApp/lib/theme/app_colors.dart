import 'package:flutter/material.dart';

/// Centralized color palette for the Nakhlah application.
///
/// All color constants previously scattered across individual screens are
/// consolidated here as a single source of truth.
abstract final class AppColors {
  // ── General palette (used in main.dart theme) ───────────────────────────
  static const Color palmGreen = Color(0xFF2E5B3E);
  static const Color goldenDate = Color(0xFFD4A373);
  static const Color offWhite = Color(0xFFF9F7F3);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5DFD8);

  // ── Brown palette (home_page, market, explore, profile) ─────────────────
  static const Color brown900 = Color(0xFF3B1F13);
  static const Color brown700 = Color(0xFF5C3A1E);
  static const Color brown100 = Color(0xFFF2EDE8);
  static const Color goldBadge = Color(0xFFE8B84B);
  static const Color cardBg = Color(0xFFEAE4DE);

  // ── Market / Explore shared tokens ──────────────────────────────────────
  static const Color screenBg = Color(0xFFF5F0EB);
  static const Color chipActive = Color(0xFF3B1F13);

  // ── Auth screen tokens (sign_in, sign_up) ───────────────────────────────
  static const Color bgCream = Color(0xFFFAF6F1);
  static const Color fieldBg = Color(0xFFFFFDFA);
  static const Color fieldBorder = Color(0xFFE8E0D6);
  static const Color fieldIcon = Color(0xFF8B7355);
  static const Color labelColor = Color(0xFF5C4A3A);
  static const Color hintColor = Color(0xFFBDB0A3);
  static const Color titleColor = Color(0xFF3E2C1F);
  static const Color buttonBg = Color(0xFF4A3728);
  static const Color linkBrown = Color(0xFF6B4F3A);
  static const Color termsText = Color(0xFF9E8E7E);

  // ── Accent / badge colors ───────────────────────────────────────────────
  static const Color gold = Color(0xFFE8B84B);
  static const Color goldDark = Color(0xFF8B6914);
  static const Color verifiedGreen = Color(0xFF1B6B3A);
  static const Color scannerGold = Color(0xFFD4A017);
}
