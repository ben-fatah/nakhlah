import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// A pill-shaped button that toggles between Arabic and English.
///
/// Shows a flag emoji + language label. Reacts instantly to locale changes
/// via [ValueListenableBuilder] so it stays in sync everywhere.
///
/// Usage:
/// ```dart
/// const LangToggleButton()
/// ```
class LangToggleButton extends StatelessWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeProvider,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';

        // Next language label (what tapping will switch TO)
        final nextFlag = isAr ? '🇺🇸' : '🇸🇦';
        final nextLabel = isAr ? 'EN' : 'ع';

        return Tooltip(
          message: isAr ? 'Switch to English' : 'التبديل إلى العربية',
          child: GestureDetector(
            onTap: localeProvider.toggleLocale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.brown900.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brown900.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flag emoji
                  Text(
                    nextFlag,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  // Language code label
                  Text(
                    nextLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brown900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
