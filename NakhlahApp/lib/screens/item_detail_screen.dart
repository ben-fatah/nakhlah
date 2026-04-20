import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_item.dart';
import '../models/seller_profile.dart';
import '../providers/locale_provider.dart';
import '../repositories/marketplace_seller_repository.dart';
import '../theme/app_colors.dart';

/// Shows full detail for a [MarketItem].
///
/// Displays image, title, description, price (or "negotiate"), seller info,
/// and a "Contact Seller" button that will open [ChatScreen] in Phase 3.
class ItemDetailScreen extends StatelessWidget {
  final MarketItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(isAr),
                    const SizedBox(height: 16),
                    _buildPriceChip(isAr),
                    const SizedBox(height: 24),
                    _buildSectionLabel(isAr ? 'وصف المنتج' : 'Description'),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel(isAr ? 'البائع' : 'Seller'),
                    const SizedBox(height: 12),
                    _SellerCard(item: item, isAr: isAr),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Sticky "Contact Seller" bottom bar
        bottomNavigationBar: _ContactBar(item: item, isAr: isAr),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.brown900,
      leading: IconButton(
        icon: Icon(
          localeProvider.isArabic
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: item.imageUrl.isNotEmpty
            ? Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brown900, AppColors.brown700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.eco_rounded, color: Colors.white38, size: 60),
        ),
      );

  Widget _buildTitleRow(bool isAr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.title,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.brown900,
              height: 1.3,
            ),
          ),
        ),
        if (item.variety.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldBadge.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.goldBadge.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              item.variety[0].toUpperCase() + item.variety.substring(1),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceChip(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: item.price != null
            ? AppColors.brown900
            : AppColors.verifiedGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.price != null
                ? Icons.payments_outlined
                : Icons.handshake_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            item.priceLabel(isAr),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.goldBadge,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.brown700,
          ),
        ),
      ],
    );
  }
}

// ── Seller Info Card ───────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final MarketItem item;
  final bool isAr;

  const _SellerCard({required this.item, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SellerProfile?>(
      future: MarketplaceSellerRepository.instance.getSeller(item.sellerId),
      builder: (context, snap) {
        final seller = snap.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown700.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brown100,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ClipOval(
                  child: (item.sellerAvatarUrl.isNotEmpty)
                      ? Image.network(
                          item.sellerAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.sellerName,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.brown900,
                      ),
                    ),
                    if (seller != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.brown700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            seller.location,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (seller.reviewCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.goldBadge,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${seller.ratingFormatted} (${seller.reviewCount})',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarFallback() {
    final initial =
        item.sellerName.isNotEmpty ? item.sellerName[0].toUpperCase() : 'S';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cairo(
          color: AppColors.brown700,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Contact Bar ────────────────────────────────────────────────────────────────

class _ContactBar extends StatelessWidget {
  final MarketItem item;
  final bool isAr;

  const _ContactBar({required this.item, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Phase 3: will open ChatScreen(item: item)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr ? 'خاصية الدردشة قادمة قريباً!' : 'Chat coming in Phase 3!',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppColors.brown700,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(
              isAr ? 'تواصل مع البائع' : 'Contact Seller',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brown700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
}
