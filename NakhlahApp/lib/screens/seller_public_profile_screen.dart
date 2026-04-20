import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/seller_profile.dart';
import '../models/seller_review.dart';
import '../providers/locale_provider.dart';
import '../repositories/seller_review_repository.dart';
import '../theme/app_colors.dart';

/// Public view of a seller's profile, including their information and reviews.
class SellerPublicProfileScreen extends StatelessWidget {
  final SellerProfile seller;

  const SellerPublicProfileScreen({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'حساب البائع' : 'Seller Profile',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildHeader(isAr),
              Container(
                color: Colors.white,
                child: TabBar(
                  indicatorColor: AppColors.goldDark,
                  indicatorWeight: 3,
                  labelColor: AppColors.brown900,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(text: isAr ? 'عن البائع' : 'About'),
                    Tab(
                      text: isAr
                          ? 'التقييمات (${seller.reviewCount})'
                          : 'Reviews (${seller.reviewCount})',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAboutTab(isAr),
                    _ReviewsTab(sellerId: seller.uid, isAr: isAr),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAr) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brown100,
              border: Border.all(color: AppColors.borderLight, width: 2),
            ),
            child: ClipOval(
              child: seller.avatarUrl.isNotEmpty
                  ? Image.network(
                      seller.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            seller.displayName,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.brown900,
            ),
          ),
          if (seller.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.brown700),
                const SizedBox(width: 4),
                Text(
                  seller.location,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Aggregate Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldBadge.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.goldBadge, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      seller.ratingFormatted,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    final initial = seller.displayName.isNotEmpty
        ? seller.displayName[0].toUpperCase()
        : 'S';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cairo(
          color: AppColors.brown700,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAboutTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          isAr ? 'نبذة عن البائع' : 'About the Seller',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.brown900,
          ),
        ),
        const SizedBox(height: 12),
        if (seller.bio.isNotEmpty)
          Text(
            seller.bio,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          )
        else
          Text(
            isAr
                ? 'لا توجد نبذة تعريفية.'
                : 'No bio provided.',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

// ── Reviews Tab ────────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final String sellerId;
  final bool isAr;

  const _ReviewsTab({required this.sellerId, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SellerReview>>(
      stream: SellerReviewRepository.instance.watchSellerReviews(sellerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brown700),
          );
        }

        final reviews = snap.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'لا توجد تقييمات بعد' : 'No reviews yet',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _ReviewCard(review: reviews[i]),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final SellerReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.brown900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStars(review.rating),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(review.createdAt),
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 14,
          color: i < rating ? AppColors.goldBadge : Colors.grey.shade300,
        );
      }),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year) {
      return '${dt.day}/${dt.month}';
    }
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }
}
