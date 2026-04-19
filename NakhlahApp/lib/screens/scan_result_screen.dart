import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_result.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import 'market_screen.dart' as market;

class ScanResultScreen extends StatelessWidget {
  final ScanResult result;
  const ScanResultScreen({super.key, required this.result});

  Future<void> _share(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;
    final text = l.shareText(
      result.localizedName(isAr),
      result.localizedOrigin(isAr),
      result.confidencePercent,
    );
    await Share.share(text);
  }

  void _goToMarket(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const market.MarketScreen()));
  }

  void _scanAgain(BuildContext context) => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9F6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              color: AppColors.brown700,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l.scanResult,
            style: GoogleFonts.cairo(
              color: AppColors.brown900,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.brown700),
              onPressed: () => _share(context),
              tooltip: l.shareResults,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // ✅ Hero image — shows user's actual photo
                _HeroCard(result: result, l: l),
                const SizedBox(height: 20),
                Text(
                  result.nameEn,
                  style: GoogleFonts.cairo(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brown700,
                    height: 1.1,
                  ),
                ),
                Text(
                  result.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    color: const Color(0xFFA1887F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                _OriginCard(result: result, l: l, isAr: isAr),
                const SizedBox(height: 24),
                Text(
                  l.nutritionPer100g,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _NutritionGrid(result: result, l: l),
                const SizedBox(height: 32),
                _ActionButtons(
                  l: l,
                  onFindSellers: () => _goToMarket(context),
                  onShare: () => _share(context),
                  onScanAgain: () => _scanAgain(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero image card ───────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final ScanResult result;
  final AppLocalizations l;
  const _HeroCard({required this.result, required this.l});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildImage(),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brown900.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: AppColors.goldBadge,
                ),
                const SizedBox(width: 5),
                Text(
                  '${result.confidencePercent} ${l.confidence}',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    // Priority 1: local file from camera/gallery (the actual photo the user took)
    if (result.localImagePath != null && result.localImagePath!.isNotEmpty) {
      return Image.file(
        File(result.localImagePath!),
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    // Priority 2: network URL from API
    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return Image.network(
        result.imageUrl!,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    // Fallback: gradient placeholder
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.brown900, AppColors.brown700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, color: Colors.white38, size: 72),
      ),
    );
  }
}

// ── Origin card ───────────────────────────────────────────────────────────────

class _OriginCard extends StatelessWidget {
  final ScanResult result;
  final AppLocalizations l;
  final bool isAr;
  const _OriginCard({
    required this.result,
    required this.l,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.brown700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l.origin,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  result.localizedOrigin(isAr),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.brown900,
                  ),
                ),
                const SizedBox(height: 10),
                _VerifiedBadge(label: l.verifiedOrigin),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brown100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: AppColors.brown700,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition grid ────────────────────────────────────────────────────────────

class _NutritionGrid extends StatelessWidget {
  final ScanResult result;
  final AppLocalizations l;
  const _NutritionGrid({required this.result, required this.l});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _NutrientCard(
          label: l.caloriesLabel,
          value: '${result.calories}',
          unit: 'kcal',
        ),
        _NutrientCard(label: l.carbsLabel, value: '${result.carbs}', unit: 'g'),
        _NutrientCard(label: l.fiberLabel, value: '${result.fiber}', unit: 'g'),
        _NutrientCard(
          label: l.potassiumLabel,
          value: '${result.potassium}',
          unit: 'mg',
        ),
      ],
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onFindSellers, onShare, onScanAgain;
  const _ActionButtons({
    required this.l,
    required this.onFindSellers,
    required this.onShare,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onFindSellers,
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              l.findSellers,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    l.shareResults,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brown700,
                    side: const BorderSide(
                      color: AppColors.brown700,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.filter_center_focus_rounded, size: 18),
                  label: Text(
                    l.scanAgain,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brown900,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _NutrientCard extends StatelessWidget {
  final String label, value, unit;
  const _NutrientCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brown900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final String label;
  const _VerifiedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 12,
            color: AppColors.verifiedGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.verifiedGreen,
            ),
          ),
        ],
      ),
    );
  }
}
