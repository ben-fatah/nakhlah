import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/scan_history_notifier.dart';
import '../l10n/app_localizations.dart';
import '../models/scan_result.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import 'scan_result_screen.dart';

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
        body: Column(
          children: [
            _HistoryHeader(l: l),
            Expanded(
              child: ValueListenableBuilder<List<ScanHistoryEntry>>(
                valueListenable: scanHistoryNotifier,
                builder: (context, scans, _) {
                  if (scans.isEmpty) return _EmptyHistory(l: l);
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: scans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _ScanHistoryCard(entry: scans[i], l: l, isAr: isAr),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header (matches all other screens) ───────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  final AppLocalizations l;
  const _HistoryHeader({required this.l});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brown900, AppColors.brown700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.scanHistory,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                ValueListenableBuilder<List<ScanHistoryEntry>>(
                  valueListenable: scanHistoryNotifier,
                  builder: (_, scans, _) => Text(
                    l.isArabic
                        ? '${scans.length} عملية مسح'
                        : '${scans.length} scan${scans.length == 1 ? '' : 's'}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Clear all
          ValueListenableBuilder<List<ScanHistoryEntry>>(
            valueListenable: scanHistoryNotifier,
            builder: (_, scans, _) {
              if (scans.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _showClearDialog(context, l),
                child: Text(
                  l.isArabic ? 'مسح الكل' : 'Clear All',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l.isArabic ? 'مسح السجل؟' : 'Clear History?',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.isArabic
              ? 'سيتم حذف جميع سجلات المسح.'
              : 'All scan records will be permanently deleted.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(),
            ),
          ),
          TextButton(
            onPressed: () {
              scanHistoryNotifier.clear();
              Navigator.pop(context);
            },
            child: Text(
              l.isArabic ? 'مسح' : 'Clear',
              style: GoogleFonts.cairo(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────
class _ScanHistoryCard extends StatelessWidget {
  final ScanHistoryEntry entry;
  final AppLocalizations l;
  final bool isAr;

  const _ScanHistoryCard({
    required this.entry,
    required this.l,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => scanHistoryNotifier.remove(entry.id),
      child: GestureDetector(
        onTap: () {
          final result = ScanResult(
            nameEn: entry.nameEn,
            nameAr: entry.nameAr,
            originEn: entry.originEn,
            originAr: entry.originAr,
            confidence: entry.confidence,
            calories: entry.calories,
            carbs: entry.carbs,
            fiber: entry.fiber,
            potassium: entry.potassium,
            imageUrl: entry.imageUrl,
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown900.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image — priority: network URL > local file > fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildEntryImage(entry),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? entry.nameAr : entry.nameEn,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isAr ? entry.originAr : entry.originEn,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.matchPercent}% ${l.isArabic ? 'دقة' : 'match'}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(entry.scannedAt, isAr),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brown700,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryImage(ScanHistoryEntry entry) {
    // 1. Firebase Storage URL (persists cross-device)
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      return Image.network(
        entry.imageUrl!,
        width: 64, height: 64, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _localOrFallback(entry),
      );
    }
    return _localOrFallback(entry);
  }

  Widget _localOrFallback(ScanHistoryEntry entry) {
    // 2. Local temp file path (same-session, may be deleted by OS)
    if (entry.imagePath.isNotEmpty &&
        !entry.imagePath.startsWith('assets/') &&
        File(entry.imagePath).existsSync()) {
      return Image.file(
        File(entry.imagePath),
        width: 64, height: 64, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    // 3. Generic placeholder
    return _fallback();
  }

  Widget _fallback() => Container(
    width: 64,
    height: 64,
    color: AppColors.brown100,
    child: const Icon(Icons.eco_rounded, color: AppColors.brown700, size: 28),
  );

  String _formatDate(DateTime dt, bool isAr) {
    final months = isAr
        ? [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
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
