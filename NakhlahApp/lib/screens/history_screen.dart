import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// Displays the user's scan history.
///
/// Currently shows an empty state. When scan history is persisted to Firestore,
/// replace the [_EmptyHistory] widget with a [ListView.builder] that reads from
/// your history repository.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2EDE8),
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l.scanHistory,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _EmptyHistory(l: l),
          // ── TODO: Replace the line above with the list below once
          //          scan history is stored:
          //
          // child: ListView.builder(
          //   padding: const EdgeInsets.all(20),
          //   itemCount: scans.length,
          //   itemBuilder: (context, i) => _ScanHistoryCard(scan: scans[i]),
          // ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyHistory({required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.brown100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown900.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 52,
                color: AppColors.brown700,
              ),
            ),
            const SizedBox(height: 28),

            Text(
              l.noScansYet,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.brown900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.noScansYetSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // CTA — go back to scan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.filter_center_focus_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  l.scanNow,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
