import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/seller_profile.dart';
import '../providers/locale_provider.dart';
import '../repositories/marketplace_seller_repository.dart';
import '../theme/app_colors.dart';
import 'chat_list_screen.dart';
import 'items_management_screen.dart';

/// Seller dashboard — the primary hub for a seller account.
///
/// **Phase 1 (skeleton)**
/// - Shows seller's shop name, location, and avatar.
/// - Displays three navigation tiles: My Items, Messages, Requests.
/// - Tiles are tappable but navigate to placeholder screens for now.
///   They will be wired to real implementations in Phases 2 & 3.
///
/// **Entry points**
/// - Immediately after [SellerOnboardingScreen] completes.
/// - When a seller taps "My Seller Dashboard" in [ManageProfileScreen].
class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final _repo = MarketplaceSellerRepository.instance;

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: StreamBuilder<SellerProfile?>(
          stream: _repo.watchCurrentSeller(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brown700),
              );
            }

            final seller = snap.data;
            if (seller == null) {
              // Not yet a seller — should not normally reach here.
              return const Center(child: Text('Seller profile not found.'));
            }

            return CustomScrollView(
              slivers: [
                _buildAppBar(context, seller, isAr),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ShopStatsRow(seller: seller, isAr: isAr),
                      const SizedBox(height: 28),
                      _buildSectionLabel(
                        isAr ? 'إدارة المتجر' : 'Manage Shop',
                      ),
                      const SizedBox(height: 16),
                      _DashboardTile(
                        icon: Icons.inventory_2_outlined,
                        label: isAr ? 'منتجاتي' : 'My Items',
                        subtitle: isAr
                            ? 'أضف وعدّل منتجاتك'
                            : 'Add and manage your listings',
                        color: AppColors.brown700,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ItemsManagementScreen(seller: seller),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DashboardTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: isAr ? 'الرسائل' : 'Messages',
                        subtitle: isAr
                            ? 'تواصل مع المشترين'
                            : 'Chat with buyers',
                        color: const Color(0xFF2E6B4F),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatListScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DashboardTile(
                        icon: Icons.star_outline_rounded,
                        label: isAr ? 'التقييمات' : 'Reviews',
                        subtitle: isAr
                            ? 'آراء العملاء'
                            : 'What buyers say about you',
                        color: const Color(0xFF8B6914),
                        // Phase 4: will navigate to ReviewsScreen
                        onTap: () => _comingSoon(context, isAr),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    SellerProfile seller,
    bool isAr,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.brown900,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(
                isAr
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brown900, AppColors.brown700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldBadge.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.goldBadge.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: seller.avatarUrl.isNotEmpty
                          ? Image.network(
                              seller.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(seller),
                            )
                          : _avatarFallback(seller),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.displayName,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.goldBadge,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              seller.location,
                              style: GoogleFonts.cairo(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldBadge.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.goldBadge.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.goldBadge,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'بائع موثق' : 'Verified Seller',
                                style: GoogleFonts.cairo(
                                  color: AppColors.goldBadge,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(SellerProfile seller) {
    final initial = seller.displayName.isNotEmpty
        ? seller.displayName[0].toUpperCase()
        : 'S';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cairo(
          color: AppColors.goldBadge,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
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

  void _comingSoon(BuildContext context, bool isAr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'قريباً...' : 'Coming in the next phase!',
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.brown700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Shop Stats Row ─────────────────────────────────────────────────────────────

class _ShopStatsRow extends StatelessWidget {
  final SellerProfile seller;
  final bool isAr;

  const _ShopStatsRow({required this.seller, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.star_rounded,
          value: seller.ratingFormatted,
          label: isAr ? 'التقييم' : 'Rating',
          iconColor: AppColors.goldBadge,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.rate_review_outlined,
          value: seller.reviewCount.toString(),
          label: isAr ? 'تقييمات' : 'Reviews',
          iconColor: AppColors.brown700,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
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
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brown900,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Tile ─────────────────────────────────────────────────────────────

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
